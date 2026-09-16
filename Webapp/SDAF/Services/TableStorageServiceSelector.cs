// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    /// <summary>
    /// Service selector that implements repository-first with storage fallback strategy.
    /// Delegates to repository or storage implementation based on persistence mode.
    /// </summary>
    public class TableStorageServiceSelector<T> : ITableStorageService<T> where T : class
    {
        private readonly RepositoryPersistenceMode _persistenceMode;
        private readonly ITableStorageService<T> _repositoryService;
        private readonly ITableStorageService<T> _storageService;
        private readonly ILogger<TableStorageServiceSelector<T>> _logger;

        public TableStorageServiceSelector(
            IOptions<RepositoryPersistenceSettings> persistenceSettings,
            ITableStorageService<T> repositoryService,
            ITableStorageService<T> storageService,
            ILogger<TableStorageServiceSelector<T>> logger)
        {
            _persistenceMode = persistenceSettings.Value?.GetPersistenceMode()
                ?? RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback;
            _repositoryService = repositoryService ?? throw new ArgumentNullException(nameof(repositoryService));
            _storageService = storageService ?? throw new ArgumentNullException(nameof(storageService));
            _logger = logger;

            _logger?.LogInformation(
                "TableStorageServiceSelector<{EntityType}> initialized with mode: {Mode}",
                typeof(T).Name, _persistenceMode);
        }

        public async Task<List<T>> GetNAsync(int n)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => await _repositoryService.GetNAsync(n),
                RepositoryPersistenceMode.StorageOnly => await _storageService.GetNAsync(n),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    await GetNWithFallbackAsync(n),
                _ => await _storageService.GetNAsync(n)
            };
        }

        public async Task<List<T>> GetAllAsync()
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => await _repositoryService.GetAllAsync(),
                RepositoryPersistenceMode.StorageOnly => await _storageService.GetAllAsync(),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    await GetAllWithFallbackAsync(),
                _ => await _storageService.GetAllAsync()
            };
        }

        public async Task<List<T>> GetAllAsync(string partitionKey)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => await _repositoryService.GetAllAsync(partitionKey),
                RepositoryPersistenceMode.StorageOnly => await _storageService.GetAllAsync(partitionKey),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    await GetAllWithFallbackAsync(partitionKey),
                _ => await _storageService.GetAllAsync(partitionKey)
            };
        }

        public async Task<T> GetByIdAsync(string rowKey, string partitionKey)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly =>
                    await _repositoryService.GetByIdAsync(rowKey, partitionKey),
                RepositoryPersistenceMode.StorageOnly =>
                    await _storageService.GetByIdAsync(rowKey, partitionKey),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    await GetByIdWithFallbackAsync(rowKey, partitionKey),
                _ => await _storageService.GetByIdAsync(rowKey, partitionKey)
            };
        }

        public async Task<T> GetDefault()
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => await _repositoryService.GetDefault(),
                RepositoryPersistenceMode.StorageOnly => await _storageService.GetDefault(),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    await GetDefaultWithFallbackAsync(),
                _ => await _storageService.GetDefault()
            };
        }

        public async Task CreateAsync(T model)
        {
            try
            {
                if (_persistenceMode == RepositoryPersistenceMode.StorageOnly)
                {
                    await _storageService.CreateAsync(model);
                }
                else
                {
                    // Try repository first
                    await _repositoryService.CreateAsync(model);

                    // Also write to storage if in fallback mode (for redundancy during transition)
                    if (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
                    {
                        try
                        {
                            await _storageService.CreateAsync(model);
                        }
                        catch (Exception ex)
                        {
                            _logger?.LogWarning(
                                ex,
                                "Failed to write to storage fallback during create for {EntityType}. Repository write succeeded.",
                                typeof(T).Name);
                            // Don't fail the operation; repository write is what matters
                        }
                    }
                }
            }
            catch (Exception ex) when (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
            {
                _logger?.LogWarning(
                    ex,
                    "Repository create failed for {EntityType}, attempting fallback to storage.",
                    typeof(T).Name);

                // Try storage fallback
                try
                {
                    await _storageService.CreateAsync(model);
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(
                        fallbackEx,
                        "Storage fallback also failed after repository create failed for {EntityType}.",
                        typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to create {typeof(T).Name}: repository failed and storage fallback also failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }
        }

        public async Task UpdateAsync(T model)
        {
            try
            {
                if (_persistenceMode == RepositoryPersistenceMode.StorageOnly)
                {
                    await _storageService.UpdateAsync(model);
                }
                else
                {
                    // Try repository first
                    await _repositoryService.UpdateAsync(model);

                    // Also write to storage if in fallback mode (for redundancy during transition)
                    if (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
                    {
                        try
                        {
                            await _storageService.UpdateAsync(model);
                        }
                        catch (Exception ex)
                        {
                            _logger?.LogWarning(
                                ex,
                                "Failed to write to storage fallback during update for {EntityType}. Repository write succeeded.",
                                typeof(T).Name);
                            // Don't fail the operation; repository write is what matters
                        }
                    }
                }
            }
            catch (Exception ex) when (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
            {
                _logger?.LogWarning(
                    ex,
                    "Repository update failed for {EntityType}, attempting fallback to storage.",
                    typeof(T).Name);

                // Try storage fallback
                try
                {
                    await _storageService.UpdateAsync(model);
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(
                        fallbackEx,
                        "Storage fallback also failed after repository update failed for {EntityType}.",
                        typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to update {typeof(T).Name}: repository failed and storage fallback also failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }
        }

        public async Task DeleteAsync(string rowKey, string partitionKey)
        {
            try
            {
                if (_persistenceMode == RepositoryPersistenceMode.StorageOnly)
                {
                    await _storageService.DeleteAsync(rowKey, partitionKey);
                }
                else
                {
                    // Try repository first
                    await _repositoryService.DeleteAsync(rowKey, partitionKey);

                    // Also delete from storage if in fallback mode (for redundancy during transition)
                    if (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
                    {
                        try
                        {
                            await _storageService.DeleteAsync(rowKey, partitionKey);
                        }
                        catch (Exception ex)
                        {
                            _logger?.LogWarning(
                                ex,
                                "Failed to delete from storage fallback for {EntityType}. Repository delete succeeded.",
                                typeof(T).Name);
                            // Don't fail the operation; repository delete is what matters
                        }
                    }
                }
            }
            catch (Exception ex) when (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
            {
                _logger?.LogWarning(
                    ex,
                    "Repository delete failed for {EntityType}, attempting fallback to storage.",
                    typeof(T).Name);

                // Try storage fallback
                try
                {
                    await _storageService.DeleteAsync(rowKey, partitionKey);
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(
                        fallbackEx,
                        "Storage fallback also failed after repository delete failed for {EntityType}.",
                        typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to delete {typeof(T).Name}: repository failed and storage fallback also failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }
        }

        public async Task CreateTFVarsAsync(AppFile file)
        {
            try
            {
                if (_persistenceMode == RepositoryPersistenceMode.StorageOnly)
                {
                    await _storageService.CreateTFVarsAsync(file);
                }
                else
                {
                    await _repositoryService.CreateTFVarsAsync(file);

                    if (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
                    {
                        try
                        {
                            await _storageService.CreateTFVarsAsync(file);
                        }
                        catch (Exception ex)
                        {
                            _logger?.LogWarning(ex, "Failed to create TFVars in storage fallback. Repository write succeeded.");
                        }
                    }
                }
            }
            catch (Exception ex) when (_persistenceMode == RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback)
            {
                try
                {
                    await _storageService.CreateTFVarsAsync(file);
                }
                catch (Exception fallbackEx)
                {
                    throw new InvalidOperationException(
                        "Failed to create TFVars: repository failed and storage fallback also failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }
        }

        // Private fallback methods
        private async Task<List<T>> GetNWithFallbackAsync(int n)
        {
            try
            {
                return await _repositoryService.GetNAsync(n);
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Repository GetN failed for {EntityType}, falling back to storage.", typeof(T).Name);
                try
                {
                    return await _storageService.GetNAsync(n);
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(fallbackEx, "Storage fallback also failed for GetN {EntityType}.", typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to get {n} {typeof(T).Name}: both repository and storage failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }
        }

        private async Task<List<T>> GetAllWithFallbackAsync()
        {
            List<T> repositoryResult;
            try
            {
                repositoryResult = await _repositoryService.GetAllAsync();
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Repository GetAll failed for {EntityType}, falling back to storage.", typeof(T).Name);
                try
                {
                    return await _storageService.GetAllAsync();
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(fallbackEx, "Storage fallback also failed for GetAll {EntityType}.", typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to get all {typeof(T).Name}: both repository and storage failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }

            // The repository-backed implementations treat a "not found" root/partition
            // directory as an empty result rather than throwing, so an empty repository
            // result does not necessarily mean the exception-based fallback above ran.
            // Explicitly fall back to storage in that case so entities that only exist
            // in legacy Table Storage (not yet migrated to the repository) are still returned.
            if (repositoryResult == null || repositoryResult.Count == 0)
            {
                try
                {
                    var storageResult = await _storageService.GetAllAsync();
                    if (storageResult != null && storageResult.Count > 0)
                    {
                        _logger?.LogInformation(
                            "Repository returned no {EntityType} entities; using storage fallback which returned {Count}.",
                            typeof(T).Name, storageResult.Count);
                        return storageResult;
                    }
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogWarning(fallbackEx, "Storage fallback also returned no results for empty GetAll {EntityType}.", typeof(T).Name);
                }
            }

            return repositoryResult ?? new List<T>();
        }

        private async Task<List<T>> GetAllWithFallbackAsync(string partitionKey)
        {
            List<T> repositoryResult;
            try
            {
                repositoryResult = await _repositoryService.GetAllAsync(partitionKey);
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Repository GetAll for partition {PartitionKey} failed for {EntityType}, falling back to storage.", partitionKey, typeof(T).Name);
                try
                {
                    return await _storageService.GetAllAsync(partitionKey);
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(fallbackEx, "Storage fallback also failed for GetAll partition {PartitionKey} {EntityType}.", partitionKey, typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to get all {typeof(T).Name} for partition {partitionKey}: both repository and storage failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }

            // See comment in the parameterless overload: an empty repository result
            // can mean "not yet migrated", so explicitly try storage too.
            if (repositoryResult == null || repositoryResult.Count == 0)
            {
                try
                {
                    var storageResult = await _storageService.GetAllAsync(partitionKey);
                    if (storageResult != null && storageResult.Count > 0)
                    {
                        _logger?.LogInformation(
                            "Repository returned no {EntityType} entities for partition {PartitionKey}; using storage fallback which returned {Count}.",
                            typeof(T).Name, partitionKey, storageResult.Count);
                        return storageResult;
                    }
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogWarning(fallbackEx, "Storage fallback also returned no results for empty GetAll partition {PartitionKey} {EntityType}.", partitionKey, typeof(T).Name);
                }
            }

            return repositoryResult ?? new List<T>();
        }

        private async Task<T> GetByIdWithFallbackAsync(string rowKey, string partitionKey)
        {
            T repositoryResult;
            try
            {
                repositoryResult = await _repositoryService.GetByIdAsync(rowKey, partitionKey);
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Repository GetById {RowKey}/{PartitionKey} failed for {EntityType}, falling back to storage.", rowKey, partitionKey, typeof(T).Name);
                try
                {
                    return await _storageService.GetByIdAsync(rowKey, partitionKey);
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(fallbackEx, "Storage fallback also failed for GetById {RowKey}/{PartitionKey} {EntityType}.", rowKey, partitionKey, typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to get {typeof(T).Name} {rowKey}/{partitionKey}: both repository and storage failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }

            // The repository-backed GetByIdAsync implementations for Landscape/System
            // return null on "not found" rather than throwing, so a null result does not
            // necessarily mean the exception-based fallback above ran. Explicitly try
            // storage in that case so entities that only exist in legacy Table Storage
            // (not yet migrated to the repository) can still be found.
            if (repositoryResult == null)
            {
                try
                {
                    var storageResult = await _storageService.GetByIdAsync(rowKey, partitionKey);
                    if (storageResult != null)
                    {
                        _logger?.LogInformation(
                            "Repository returned no {EntityType} for {RowKey}/{PartitionKey}; found it via storage fallback.",
                            typeof(T).Name, rowKey, partitionKey);
                        return storageResult;
                    }
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogWarning(fallbackEx, "Storage fallback also failed to find {EntityType} {RowKey}/{PartitionKey}.", typeof(T).Name, rowKey, partitionKey);
                }
            }

            return repositoryResult;
        }

        private async Task<T> GetDefaultWithFallbackAsync()
        {
            try
            {
                return await _repositoryService.GetDefault();
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Repository GetDefault failed for {EntityType}, falling back to storage.", typeof(T).Name);
                try
                {
                    return await _storageService.GetDefault();
                }
                catch (Exception fallbackEx)
                {
                    _logger?.LogError(fallbackEx, "Storage fallback also failed for GetDefault {EntityType}.", typeof(T).Name);
                    throw new InvalidOperationException(
                        $"Failed to get default {typeof(T).Name}: both repository and storage failed.",
                        new AggregateException(ex, fallbackEx));
                }
            }
        }
    }
}
