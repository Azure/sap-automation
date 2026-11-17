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
    /// Routes persistence operations to the configured backend.
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
            ArgumentNullException.ThrowIfNull(persistenceSettings);
            _persistenceMode = persistenceSettings.Value.GetPersistenceMode();
            _repositoryService = repositoryService ?? throw new ArgumentNullException(nameof(repositoryService));
            _storageService = storageService ?? throw new ArgumentNullException(nameof(storageService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public Task<List<T>> GetNAsync(int n)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => _repositoryService.GetNAsync(n),
                RepositoryPersistenceMode.StorageOnly => _storageService.GetNAsync(n),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    ReadCollectionWithFallbackAsync(
                        () => _repositoryService.GetNAsync(n),
                        () => _storageService.GetNAsync(n),
                        nameof(GetNAsync)),
                _ => throw CreateUnknownModeException()
            };
        }

        public Task<List<T>> GetAllAsync()
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => _repositoryService.GetAllAsync(),
                RepositoryPersistenceMode.StorageOnly => _storageService.GetAllAsync(),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    ReadCollectionWithFallbackAsync(
                        _repositoryService.GetAllAsync,
                        _storageService.GetAllAsync,
                        nameof(GetAllAsync)),
                _ => throw CreateUnknownModeException()
            };
        }

        public Task<List<T>> GetAllAsync(string partitionKey)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => _repositoryService.GetAllAsync(partitionKey),
                RepositoryPersistenceMode.StorageOnly => _storageService.GetAllAsync(partitionKey),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    ReadCollectionWithFallbackAsync(
                        () => _repositoryService.GetAllAsync(partitionKey),
                        () => _storageService.GetAllAsync(partitionKey),
                        nameof(GetAllAsync)),
                _ => throw CreateUnknownModeException()
            };
        }

        public Task<T> GetByIdAsync(string rowKey, string partitionKey)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => _repositoryService.GetByIdAsync(rowKey, partitionKey),
                RepositoryPersistenceMode.StorageOnly => _storageService.GetByIdAsync(rowKey, partitionKey),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    ReadNullableWithFallbackAsync(
                        () => _repositoryService.GetByIdAsync(rowKey, partitionKey),
                        () => _storageService.GetByIdAsync(rowKey, partitionKey),
                        nameof(GetByIdAsync)),
                _ => throw CreateUnknownModeException()
            };
        }

        public Task<T> GetDefault()
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => _repositoryService.GetDefault(),
                RepositoryPersistenceMode.StorageOnly => _storageService.GetDefault(),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    ReadNullableWithFallbackAsync(
                        _repositoryService.GetDefault,
                        _storageService.GetDefault,
                        nameof(GetDefault)),
                _ => throw CreateUnknownModeException()
            };
        }

        public Task CreateAsync(T model)
        {
            return ExecuteWriteAsync(
                () => _repositoryService.CreateAsync(model),
                () => _storageService.CreateAsync(model),
                nameof(CreateAsync));
        }

        public Task UpdateAsync(T model)
        {
            return ExecuteWriteAsync(
                () => _repositoryService.UpdateAsync(model),
                () => _storageService.UpdateAsync(model),
                nameof(UpdateAsync));
        }

        public Task DeleteAsync(string rowKey, string partitionKey)
        {
            return ExecuteWriteAsync(
                () => _repositoryService.DeleteAsync(rowKey, partitionKey),
                () => _storageService.DeleteAsync(rowKey, partitionKey),
                nameof(DeleteAsync));
        }

        public Task CreateTFVarsAsync(AppFile file)
        {
            return ExecuteWriteAsync(
                () => _repositoryService.CreateTFVarsAsync(file),
                () => _storageService.CreateTFVarsAsync(file),
                nameof(CreateTFVarsAsync));
        }

        private async Task<List<T>> ReadCollectionWithFallbackAsync(
            Func<Task<List<T>>> repositoryOperation,
            Func<Task<List<T>>> storageOperation,
            string operationName)
        {
            try
            {
                return await repositoryOperation();
            }
            catch (Exception repositoryException)
            {
                LogFallback(repositoryException, operationName);
                return await ExecuteStorageFallbackAsync(storageOperation, repositoryException, operationName);
            }
        }

        private async Task<T> ReadNullableWithFallbackAsync(
            Func<Task<T>> repositoryOperation,
            Func<Task<T>> storageOperation,
            string operationName)
        {
            try
            {
                var result = await repositoryOperation();
                return result ?? await storageOperation();
            }
            catch (Exception repositoryException)
            {
                LogFallback(repositoryException, operationName);
                return await ExecuteStorageFallbackAsync(storageOperation, repositoryException, operationName);
            }
        }

        private Task ExecuteWriteAsync(
            Func<Task> repositoryOperation,
            Func<Task> storageOperation,
            string operationName)
        {
            return _persistenceMode switch
            {
                RepositoryPersistenceMode.RepositoryOnly => repositoryOperation(),
                RepositoryPersistenceMode.StorageOnly => storageOperation(),
                RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback =>
                    ExecuteWriteWithFallbackAsync(repositoryOperation, storageOperation, operationName),
                _ => throw CreateUnknownModeException()
            };
        }

        private async Task ExecuteWriteWithFallbackAsync(
            Func<Task> repositoryOperation,
            Func<Task> storageOperation,
            string operationName)
        {
            try
            {
                await repositoryOperation();
            }
            catch (Exception repositoryException)
            {
                LogFallback(repositoryException, operationName);
                await ExecuteStorageFallbackAsync(storageOperation, repositoryException, operationName);
            }
        }

        private async Task<TResult> ExecuteStorageFallbackAsync<TResult>(
            Func<Task<TResult>> storageOperation,
            Exception repositoryException,
            string operationName)
        {
            try
            {
                return await storageOperation();
            }
            catch (Exception storageException)
            {
                throw CreateAggregateFailure(operationName, repositoryException, storageException);
            }
        }

        private async Task ExecuteStorageFallbackAsync(
            Func<Task> storageOperation,
            Exception repositoryException,
            string operationName)
        {
            try
            {
                await storageOperation();
            }
            catch (Exception storageException)
            {
                throw CreateAggregateFailure(operationName, repositoryException, storageException);
            }
        }

        private void LogFallback(Exception exception, string operationName)
        {
            _logger.LogWarning(
                exception,
                "Repository {Operation} failed for {EntityType}; trying storage fallback.",
                operationName,
                typeof(T).Name);
        }

        private AggregateException CreateAggregateFailure(
            string operationName,
            Exception repositoryException,
            Exception storageException)
        {
            return new AggregateException(
                $"Both repository and storage {operationName} operations failed for {typeof(T).Name}.",
                repositoryException,
                storageException);
        }

        private InvalidOperationException CreateUnknownModeException()
        {
            return new InvalidOperationException($"Unsupported persistence mode value: {(int)_persistenceMode}.");
        }
    }
}
