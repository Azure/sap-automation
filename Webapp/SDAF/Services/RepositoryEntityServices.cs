// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

using SDAFWebApp.Controllers;

namespace SDAFWebApp.Services
{
    /// <summary>
    /// Repository-backed implementation of ITableStorageService for JSON-based entities (Landscape, System).
    /// Persists entities as JSON documents in repository at paths determined by IRepositoryPathConvention.
    /// </summary>
    public abstract class RepositoryJsonEntityService<T> : ITableStorageService<T>
    {
        protected readonly IRepositoryDataAccessProvider _dataAccessProvider;
        protected readonly IRepositoryPathConvention _pathConvention;
        protected readonly RestHelper _restHelper; // For write operations (create/update)

        protected RepositoryJsonEntityService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            RestHelper restHelper)
        {
            _dataAccessProvider = dataAccessProvider ?? throw new ArgumentNullException(nameof(dataAccessProvider));
            _pathConvention = pathConvention ?? throw new ArgumentNullException(nameof(pathConvention));
            _restHelper = restHelper ?? throw new ArgumentNullException(nameof(restHelper));
        }

        /// <summary>
        /// Gets the path builder method for this entity type (implemented by subclasses).
        /// </summary>
        protected abstract string BuildPath(string partitionKey, string rowKey);

        /// <summary>
        /// Parses path to extract partition/row keys (implemented by subclasses).
        /// </summary>
        protected abstract (string partitionKey, string rowKey) ParsePath(string path);

        /// <summary>
        /// Deserializes JSON content to entity object (for Table Storage).
        /// </summary>
        protected abstract T DeserializeJson(string content);

        /// <summary>
        /// Serializes entity object to JSON (for Table Storage).
        /// </summary>
        protected abstract string SerializeJson(T entity);

        /// <summary>
        /// Deserializes TFVARS content to entity object (for ADO/GitHub).
        /// </summary>
        protected abstract T DeserializeTfvars(string content, string partitionKey = null);

        /// <summary>
        /// Serializes entity object to TFVARS format (for ADO/GitHub).
        /// </summary>
        protected abstract string SerializeTfvars(T entity);

        /// <summary>
        /// Gets the default entity (e.g., for landscapes/systems with IsDefault=true).
        /// </summary>
        protected abstract Task<T> GetDefaultFromStorageAsync();

        /// <summary>
        /// Checks if an entity is marked as default.
        /// </summary>
        protected abstract bool IsDefault(T entity);

        public async Task<List<T>> GetNAsync(int n)
        {
            var all = await GetAllAsync();
            return all.Take(n).ToList();
        }

        public async Task<List<T>> GetAllAsync()
        {
            var result = new List<T>();

            try
            {
                // List all partition folders in the root directory (use recursionLevel=1 to only get immediate children)
                var listResponse = await _dataAccessProvider.ListFilesAsync(GetEntityRootPath());
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync] Root path: {GetEntityRootPath()}, found {listResponse.Items.Count} items");

                foreach (var item in listResponse.Items)
                {
                    System.Diagnostics.Debug.WriteLine($"[GetAllAsync] Item: path={item.Path}, isFolder={item.IsDirectory}");

                    // Look for partition folders (folders that are not the root LANDSCAPE/SYSTEM folder itself)
                    if (item.IsDirectory && item.Path.Contains("/") &&
                        !item.Path.EndsWith("LANDSCAPE", StringComparison.OrdinalIgnoreCase) &&
                        !item.Path.EndsWith("SYSTEM", StringComparison.OrdinalIgnoreCase))
                    {
                        // Extract partition key from path (e.g., "AFS-NOEU-SAP01-INFRASTRUCTURE")
                        var parts = item.Path.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                        var partitionKey = parts[parts.Length - 1];
                        System.Diagnostics.Debug.WriteLine($"[GetAllAsync] Found partition folder, calling GetAllAsync({partitionKey})");

                        // Recursively get all TFVARS files in this partition
                        var partitionResults = await GetAllAsync(partitionKey);
                        System.Diagnostics.Debug.WriteLine($"[GetAllAsync] Partition {partitionKey} returned {partitionResults.Count} entities");
                        result.AddRange(partitionResults);
                    }
                }
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync] Final result: {result.Count} total entities");
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                // Entity root directory doesn't exist yet, return empty list
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync] Root path not found: {GetEntityRootPath()}");
            }

            return result;
        }

        public async Task<List<T>> GetAllAsync(string partitionKey)
        {
            var result = new List<T>();

            try
            {
                // List files in the partition directory
                string partitionPath = GetPartitionPath(partitionKey);
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Listing partition path: {partitionPath}");

                var listResponse = await _dataAccessProvider.ListFilesAsync(partitionPath);
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Found {listResponse.Items.Count} items in partition");

                foreach (var item in listResponse.Items)
                {
                    System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Checking item: path={item.Path}, isFolder={item.IsDirectory}, isTfvars={item.Path.EndsWith(".tfvars", StringComparison.OrdinalIgnoreCase)}");

                    // Look for TFVARS files (not folders, must end with .tfvars)
                    if (!item.IsDirectory && item.Path.EndsWith(".tfvars", StringComparison.OrdinalIgnoreCase))
                    {
                        try
                        {
                            System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Reading TFVARS file: {item.Path}");
                            var fileResponse = await _dataAccessProvider.GetFileAsync(item.Path);
                            var entity = DeserializeTfvars(fileResponse.Content, partitionKey);
                            System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Successfully deserialized TFVARS file");
                            result.Add(entity);
                        }
                        catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
                        {
                            System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] File not found (race condition): {item.Path}");
                            continue;
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Error deserializing {item.Path}: {ex.GetType().Name}: {ex.Message}");
                            continue;
                        }
                    }
                }
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Returning {result.Count} entities from partition");
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                // Partition directory doesn't exist, return empty list
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Partition path not found: {GetPartitionPath(partitionKey)}");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[GetAllAsync({partitionKey})] Error listing partition: {ex.GetType().Name}: {ex.Message}");
            }

            return result;
        }

        public virtual async Task<T> GetByIdAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            string path = BuildPath(partitionKey, rowKey);
            var fileResponse = await _dataAccessProvider.GetFileAsync(path);
            return DeserializeJson(fileResponse.Content);
        }

        public async Task<T> GetDefault()
        {
            // First try to find a default entity in repository
            var allEntities = await GetAllAsync();
            var defaultEntity = allEntities.FirstOrDefault(e => IsDefault(e));

            if (defaultEntity != null)
            {
                return defaultEntity;
            }

            // Fall back to storage default if repository doesn't have one
            return await GetDefaultFromStorageAsync();
        }

        public async Task CreateAsync(T model)
        {
            if (model == null)
            {
                throw new ArgumentNullException(nameof(model));
            }

            // Extract partition/row keys from entity
            var (partitionKey, rowKey) = ExtractKeys(model);

            string path = BuildPath(partitionKey, rowKey).Replace(".json", ".tfvars");
            string content = SerializeTfvars(model);

            // Remove WORKSPACES/ prefix since UpdateRepo will add it via pathBase
            if (path.StartsWith("WORKSPACES/"))
            {
                path = path.Substring("WORKSPACES/".Length);
            }

            // Use UpdateRepo to create with commit (it handles both create and update)
            await _restHelper.UpdateRepo(path, content);
        }

        public async Task UpdateAsync(T model)
        {
            if (model == null)
            {
                throw new ArgumentNullException(nameof(model));
            }

            // Extract partition/row keys from entity
            var (partitionKey, rowKey) = ExtractKeys(model);

            string path = BuildPath(partitionKey, rowKey).Replace(".json", ".tfvars");
            string content = SerializeTfvars(model);

            // Remove WORKSPACES/ prefix since UpdateRepo will add it via pathBase
            if (path.StartsWith("WORKSPACES/"))
            {
                path = path.Substring("WORKSPACES/".Length);
            }

            // Use UpdateRepo to update with commit
            await _restHelper.UpdateRepo(path, content);
        }

        public async Task DeleteAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            string path = BuildPath(partitionKey, rowKey).Replace(".json", ".tfvars");
            var deleteRequest = new RepositoryDeleteRequest
            {
                Path = path,
                CommitMessage = $"Delete {typeof(T).Name} {rowKey} via SDAF App Service"
            };

            await _dataAccessProvider.DeleteFileAsync(deleteRequest);
        }

        public abstract Task CreateTFVarsAsync(AppFile file);

        /// <summary>
        /// Gets the root path for all entities of this type.
        /// </summary>
        protected abstract string GetEntityRootPath();

        /// <summary>
        /// Gets the partition directory path.
        /// </summary>
        protected abstract string GetPartitionPath(string partitionKey);

        /// <summary>
        /// Extracts partition and row keys from entity (implemented by subclasses).
        /// </summary>
        protected abstract (string partitionKey, string rowKey) ExtractKeys(T entity);
    }

    /// <summary>
    /// Repository-backed implementation for LandscapeEntity.
    /// Stores landscapes as JSON documents in WORKSPACES/LANDSCAPE/{environment}/{id}.json
    /// </summary>
    public class RepositoryLandscapeService : RepositoryJsonEntityService<LandscapeEntity>
    {
        private readonly IDatabaseSettings _databaseSettings;
        private readonly LandscapeService _fallbackService; // For GetDefault fallback and CreateTFVars

        public RepositoryLandscapeService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            IDatabaseSettings databaseSettings,
            LandscapeService fallbackService,
            RestHelper restHelper)
            : base(dataAccessProvider, pathConvention, restHelper)
        {
            _databaseSettings = databaseSettings ?? throw new ArgumentNullException(nameof(databaseSettings));
            _fallbackService = fallbackService;
        }

        protected override string BuildPath(string partitionKey, string rowKey)
            => _pathConvention.BuildLandscapePath(partitionKey, rowKey);

        protected override (string partitionKey, string rowKey) ParsePath(string path)
            => _pathConvention.ParseLandscapePath(path);

        protected override LandscapeEntity DeserializeJson(string content)
        {
            var jsonDoc = JsonDocument.Parse(content);
            return new LandscapeEntity
            {
                PartitionKey = jsonDoc.RootElement.GetProperty("PartitionKey").GetString(),
                RowKey = jsonDoc.RootElement.GetProperty("RowKey").GetString(),
                Landscape = jsonDoc.RootElement.GetProperty("Landscape").GetRawText(),
                IsDefault = jsonDoc.RootElement.GetProperty("IsDefault").GetBoolean()
            };
        }

        protected override string SerializeJson(LandscapeEntity entity)
        {
            return JsonSerializer.Serialize(new
            {
                entity.PartitionKey,
                entity.RowKey,
                entity.Landscape,
                entity.IsDefault
            });
        }

protected override LandscapeEntity DeserializeTfvars(string content, string partitionKey = null)
        {
            // Convert TFVARS (HCL format) to JSON first, then deserialize
            System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Content length: {content?.Length ?? 0} chars, partitionKey: {partitionKey}");

            if (string.IsNullOrEmpty(content))
            {
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Content is null or empty, returning default landscape");
                return new LandscapeEntity { PartitionKey = partitionKey, RowKey = partitionKey, Landscape = JsonSerializer.Serialize(new LandscapeModel { Id = partitionKey }) };
            }

            try
            {
                // Convert TFVARS HCL to JSON format
                string jsonContent = Helper.TfvarToJson(content);
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Converted to JSON, length: {jsonContent?.Length ?? 0} chars");

                // Deserialize JSON to LandscapeModel with case-insensitive property matching
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var landscape = JsonSerializer.Deserialize<LandscapeModel>(jsonContent, options) ?? new LandscapeModel();

                // If Id is not set from TFVARS, use partition key
                if (string.IsNullOrEmpty(landscape.Id))
                {
                    landscape.Id = partitionKey;
                }

                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Parsed landscape - Id: {landscape.Id}, Environment: {landscape.environment}, Location: {landscape.location}, NetworkLogicalName: {landscape.network_logical_name}");

                return new LandscapeEntity
                {
                    PartitionKey = landscape.Id,
                    RowKey = landscape.Id,
                    Landscape = JsonSerializer.Serialize(landscape),
                    IsDefault = landscape.IsDefault
                };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Error parsing TFVARS: {ex.GetType().Name}: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Exception stack trace: {ex.StackTrace}");
                throw new RepositoryOperationException(
                    $"Failed to deserialize TFVARS content: {ex.Message}",
                    RepositoryErrorCategory.Unknown);
            }
        }

        protected override string SerializeTfvars(LandscapeEntity entity)
        {
            // Deserialize the Landscape JSON back to LandscapeModel, then convert to TFVARS
            var landscape = JsonSerializer.Deserialize<LandscapeModel>(entity.Landscape);
            return Helper.ConvertToTerraform(landscape);
        }

        protected override async Task<LandscapeEntity> GetDefaultFromStorageAsync()
        {
            return _fallbackService != null ? await _fallbackService.GetDefault() : null;
        }

        protected override bool IsDefault(LandscapeEntity entity)
            => entity?.IsDefault ?? false;

        protected override string GetEntityRootPath()
            => "WORKSPACES/LANDSCAPE";

        protected override string GetPartitionPath(string partitionKey)
            => $"WORKSPACES/LANDSCAPE/{partitionKey}";

        protected override (string partitionKey, string rowKey) ExtractKeys(LandscapeEntity entity)
            => (entity.PartitionKey, entity.RowKey);

        /// <summary>
        /// Overrides GetByIdAsync to handle TFVARS files instead of JSON files.
        /// Repository stores landscapes as .tfvars files, not .json files.
        /// </summary>
        public override async Task<LandscapeEntity> GetByIdAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            // Build TFVARS path: WORKSPACES/LANDSCAPE/{partitionKey}/{rowKey}.tfvars
            string tfvarsPath = $"WORKSPACES/LANDSCAPE/{partitionKey}/{rowKey}.tfvars";
            System.Diagnostics.Debug.WriteLine($"[RepositoryLandscapeService.GetByIdAsync] Attempting to load TFVARS from: {tfvarsPath}");

            try
            {
                var fileResponse = await _dataAccessProvider.GetFileAsync(tfvarsPath);
                System.Diagnostics.Debug.WriteLine($"[RepositoryLandscapeService.GetByIdAsync] Successfully retrieved TFVARS file, content length: {fileResponse.Content?.Length ?? 0}");

                var landscapeEntity = DeserializeTfvars(fileResponse.Content, partitionKey);
                System.Diagnostics.Debug.WriteLine($"[RepositoryLandscapeService.GetByIdAsync] Successfully deserialized landscape: {landscapeEntity?.PartitionKey}");
                return landscapeEntity;
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                System.Diagnostics.Debug.WriteLine($"[RepositoryLandscapeService.GetByIdAsync] TFVARS file not found at {tfvarsPath}, returning null");
                return null;
            }
        }

        public override async Task CreateTFVarsAsync(AppFile file)
        {
            if (file == null)
            {
                throw new ArgumentNullException(nameof(file));
            }

            // Extract path from AppFile.Id (format: "/LANDSCAPE/{id}/{id}.tfvars")
            // Keep leading slash - UpdateRepo uses it as separator between pathBase and path
            string path = file.Id ?? throw new ArgumentNullException(nameof(file.Id));

            // Convert content bytes to string
            string content = System.Text.Encoding.UTF8.GetString(file.Content ?? Array.Empty<byte>());

            // Save tfvars file to repository
            // Path should be relative to repository root without WORKSPACES/ prefix
            // UpdateRepo will prepend the pathBase from variable group
            await _restHelper.UpdateRepo(path, content);

            // Also save to fallback service if available
            if (_fallbackService != null)
            {
                await _fallbackService.CreateTFVarsAsync(file);
            }
        }
    }

    /// <summary>
    /// Repository-backed implementation for SystemEntity.
    /// Stores systems as JSON documents in WORKSPACES/SYSTEM/{environment}/{id}.json
    /// </summary>
    public class RepositorySystemService : RepositoryJsonEntityService<SystemEntity>
    {
        private readonly IDatabaseSettings _databaseSettings;
        private readonly SystemService _fallbackService; // For GetDefault fallback and CreateTFVars

        public RepositorySystemService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            IDatabaseSettings databaseSettings,
            SystemService fallbackService,
            RestHelper restHelper)
            : base(dataAccessProvider, pathConvention, restHelper)
        {
            _databaseSettings = databaseSettings ?? throw new ArgumentNullException(nameof(databaseSettings));
            _fallbackService = fallbackService;
        }

        protected override string BuildPath(string partitionKey, string rowKey)
            => _pathConvention.BuildSystemPath(partitionKey, rowKey);

        protected override (string partitionKey, string rowKey) ParsePath(string path)
            => _pathConvention.ParseSystemPath(path);

        protected override SystemEntity DeserializeJson(string content)
        {
            var jsonDoc = JsonDocument.Parse(content);
            return new SystemEntity
            {
                PartitionKey = jsonDoc.RootElement.GetProperty("PartitionKey").GetString(),
                RowKey = jsonDoc.RootElement.GetProperty("RowKey").GetString(),
                System = jsonDoc.RootElement.GetProperty("System").GetRawText(),
                IsDefault = jsonDoc.RootElement.GetProperty("IsDefault").GetBoolean()
            };
        }

        protected override string SerializeJson(SystemEntity entity)
        {
            return JsonSerializer.Serialize(new
            {
                entity.PartitionKey,
                entity.RowKey,
                entity.System,
                entity.IsDefault
            });
        }

        protected override SystemEntity DeserializeTfvars(string content, string partitionKey = null)
        {
            // Convert TFVARS (HCL format) to JSON first, then deserialize
            System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Content length: {content?.Length ?? 0} chars, partitionKey: {partitionKey}");
            System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Content first 300 chars (RAW): {(content?.Length > 300 ? content.Substring(0, 300) : content)}");
            System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Content starts with: {(content?.Length > 50 ? content.Substring(0, 50).Replace("\n", "\\n").Replace("\r", "\\r") : "N/A")}");

            if (string.IsNullOrEmpty(content))
            {
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Content is null or empty, returning default system");
                return new SystemEntity { PartitionKey = partitionKey, RowKey = partitionKey, System = JsonSerializer.Serialize(new SystemModel { Id = partitionKey }) };
            }

            try
            {
                // Convert TFVARS HCL to JSON format
                string jsonContent = Helper.TfvarToJson(content);
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Converted to JSON, length: {jsonContent?.Length ?? 0} chars");
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] JSON first 500 chars: {(jsonContent?.Length > 500 ? jsonContent.Substring(0, 500) : jsonContent)}");

                // Deserialize JSON to SystemModel with case-insensitive property matching
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var system = JsonSerializer.Deserialize<SystemModel>(jsonContent, options) ?? new SystemModel();

                // If Id is not set from TFVARS, use partition key
                if (string.IsNullOrEmpty(system.Id))
                {
                    system.Id = partitionKey;
                }

                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Parsed system - Id: {system.Id}, Environment: {system.environment}, Location: {system.location}, NetworkLogicalName: {system.network_logical_name}");

                return new SystemEntity
                {
                    PartitionKey = system.Id,
                    RowKey = system.Id,
                    System = JsonSerializer.Serialize(system),
                    IsDefault = system.IsDefault
                };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Error parsing TFVARS: {ex.GetType().Name}: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[DeserializeTfvars] Exception stack trace: {ex.StackTrace}");
                throw new RepositoryOperationException(
                    $"Failed to deserialize TFVARS content: {ex.Message}",
                    RepositoryErrorCategory.Unknown);
            }
        }

        protected override string SerializeTfvars(SystemEntity entity)
        {
            // Deserialize the System JSON back to SystemModel, then convert to TFVARS
            var system = JsonSerializer.Deserialize<SystemModel>(entity.System);
            return Helper.ConvertToTerraform(system);
        }

        protected override async Task<SystemEntity> GetDefaultFromStorageAsync()
        {
            return _fallbackService != null ? await _fallbackService.GetDefault() : null;
        }

        protected override bool IsDefault(SystemEntity entity)
            => entity?.IsDefault ?? false;

        protected override string GetEntityRootPath()
            => "WORKSPACES/SYSTEM";

        protected override string GetPartitionPath(string partitionKey)
            => $"WORKSPACES/SYSTEM/{partitionKey}";

        protected override (string partitionKey, string rowKey) ExtractKeys(SystemEntity entity)
            => (entity.PartitionKey, entity.RowKey);

        /// <summary>
        /// Overrides GetByIdAsync to handle TFVARS files instead of JSON files.
        /// Repository stores systems as .tfvars files, not .json files.
        /// </summary>
        public override async Task<SystemEntity> GetByIdAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            // Build TFVARS path: WORKSPACES/SYSTEM/{partitionKey}/{rowKey}.tfvars
            string tfvarsPath = $"WORKSPACES/SYSTEM/{partitionKey}/{rowKey}.tfvars";
            System.Diagnostics.Debug.WriteLine($"[RepositorySystemService.GetByIdAsync] Attempting to load TFVARS from: {tfvarsPath}");

            try
            {
                var fileResponse = await _dataAccessProvider.GetFileAsync(tfvarsPath);
                System.Diagnostics.Debug.WriteLine($"[RepositorySystemService.GetByIdAsync] Successfully retrieved TFVARS file, content length: {fileResponse.Content?.Length ?? 0}");

                var systemEntity = DeserializeTfvars(fileResponse.Content, partitionKey);
                System.Diagnostics.Debug.WriteLine($"[RepositorySystemService.GetByIdAsync] Successfully deserialized system: {systemEntity?.PartitionKey}");
                return systemEntity;
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                System.Diagnostics.Debug.WriteLine($"[RepositorySystemService.GetByIdAsync] TFVARS file not found at {tfvarsPath}, returning null");
                return null;
            }
        }

        public override async Task CreateTFVarsAsync(AppFile file)
        {
            if (file == null)
            {
                throw new ArgumentNullException(nameof(file));
            }

            // Extract path from AppFile.Id (format: "/SYSTEM/{environment}/{id}/{id}.tfvars")
            // Keep leading slash - UpdateRepo uses it as separator between pathBase and path
            string path = file.Id ?? throw new ArgumentNullException(nameof(file.Id));

            // Convert content bytes to string
            string content = System.Text.Encoding.UTF8.GetString(file.Content ?? Array.Empty<byte>());

            // Save tfvars file to repository
            // Path should be relative to repository root without WORKSPACES/ prefix
            // UpdateRepo will prepend the pathBase from variable group
            await _restHelper.UpdateRepo(path, content);

            // Also save to fallback service if available
            if (_fallbackService != null)
            {
                await _fallbackService.CreateTFVarsAsync(file);
            }
        }
    }

    /// <summary>
    /// Repository-backed implementation for AppFile.
    /// Stores files as repository files (binary or text) in WORKSPACES/APPDATA/FILES/{partition}/{rowKey}
    /// Uses repository files as source of truth; create/update/delete mapped to commit operations.
    /// </summary>
    public class RepositoryAppFileService : ITableStorageService<AppFile>
    {
        private readonly IRepositoryDataAccessProvider _dataAccessProvider;
        private readonly IRepositoryPathConvention _pathConvention;
        private readonly RestHelper _restHelper;
        private readonly IDatabaseSettings _databaseSettings;
        private readonly AppFileService _fallbackService; // For fallback

        public RepositoryAppFileService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            RestHelper restHelper,
            IDatabaseSettings databaseSettings,
            AppFileService fallbackService)
        {
            _dataAccessProvider = dataAccessProvider ?? throw new ArgumentNullException(nameof(dataAccessProvider));
            _pathConvention = pathConvention ?? throw new ArgumentNullException(nameof(pathConvention));
            _restHelper = restHelper ?? throw new ArgumentNullException(nameof(restHelper));
            _databaseSettings = databaseSettings ?? throw new ArgumentNullException(nameof(databaseSettings));
            _fallbackService = fallbackService;
        }

        public async Task<List<AppFile>> GetNAsync(int n)
        {
            var all = await GetAllAsync();
            return all.Take(n).ToList();
        }

        public async Task<List<AppFile>> GetAllAsync()
        {
            var result = new List<AppFile>();

            // AppFiles path not configured, return empty list
            return result;
        }

        public async Task<List<AppFile>> GetAllAsync(string partitionKey)
        {
            var result = new List<AppFile>();

            // AppFiles path not configured, return empty list
            return result;
        }

        public async Task<AppFile> GetByIdAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            // Check if this is a custom System file (e.g., "AFS-NOEU-SAP01-X00_custom_naming.json")
            if (rowKey.Contains("_custom_", StringComparison.OrdinalIgnoreCase))
            {
                // Extract the system ID from the rowKey (everything before _custom_)
                int customIndex = rowKey.IndexOf("_custom_", StringComparison.OrdinalIgnoreCase);
                string systemId = rowKey.Substring(0, customIndex);

                // Construct path in SYSTEM folder alongside TFVARS file
                // Format: WORKSPACES/SYSTEM/{systemId}/{filename}
                string path = $"WORKSPACES/SYSTEM/{systemId}/{rowKey}";
                System.Diagnostics.Debug.WriteLine($"[RepositoryAppFileService.GetByIdAsync] Loading custom file from SYSTEM folder: {path}");

                try
                {
                    var fileResponse = await _dataAccessProvider.GetFileAsync(path);
                    return new AppFile
                    {
                        Id = rowKey,
                        Content = fileResponse.ContentBytes ?? System.Text.Encoding.UTF8.GetBytes(fileResponse.Content)
                    };
                }
                catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
                {
                    System.Diagnostics.Debug.WriteLine($"[RepositoryAppFileService.GetByIdAsync] Custom file not found: {path}");
                    // Return null or rethrow depending on requirements
                    throw;
                }
            }

            // For standard AppFiles (like VM-Images.json), use the default path convention
            string standardPath = _pathConvention.BuildAppFilePath(partitionKey, rowKey);
            var standardFileResponse = await _dataAccessProvider.GetFileAsync(standardPath);

            return new AppFile
            {
                Id = rowKey,
                Content = standardFileResponse.ContentBytes ?? System.Text.Encoding.UTF8.GetBytes(standardFileResponse.Content)
            };
        }

        public Task<AppFile> GetDefault()
        {
            return Task.FromResult<AppFile>(null);
        }

        public async Task CreateAsync(AppFile file)
        {
            if (file == null)
            {
                throw new ArgumentNullException(nameof(file));
            }

            string content = System.Text.Encoding.UTF8.GetString(file.Content ?? Array.Empty<byte>());

            // Check if this is a custom System file (e.g., "AFS-NOEU-SAP01-X00_custom_naming.json")
            if (file.Id?.Contains("_custom_", StringComparison.OrdinalIgnoreCase) == true)
            {
                // Extract the system ID from the ID (everything before _custom_)
                int customIndex = file.Id.IndexOf("_custom_", StringComparison.OrdinalIgnoreCase);
                string systemId = file.Id.Substring(0, customIndex);

                // Store in SYSTEM folder alongside TFVARS file
                // Format: /SYSTEM/{systemId}/{filename}
                string path = $"/SYSTEM/{systemId}/{file.Id}";
                System.Diagnostics.Debug.WriteLine($"[RepositoryAppFileService.CreateAsync] Creating custom file in SYSTEM folder: {path}");

                await _restHelper.UpdateRepo(path, content);
                return;
            }

            // For standard AppFiles (like VM-Images.json), use the default path convention
            var pathParts = file.Id?.Split('/') ?? new[] { "default", "default" };
            string partitionKey = pathParts.Length > 0 ? pathParts[0] : "default";
            string rowKey = pathParts.Length > 1 ? string.Join("/", pathParts.Skip(1)) : file.Id;

            string standardPath = _pathConvention.BuildAppFilePath(partitionKey, rowKey);
            await _restHelper.UpdateRepo(standardPath, content);
        }

        public async Task UpdateAsync(AppFile file)
        {
            if (file == null)
            {
                throw new ArgumentNullException(nameof(file));
            }

            string content = System.Text.Encoding.UTF8.GetString(file.Content ?? Array.Empty<byte>());

            // Check if this is a custom System file (e.g., "AFS-NOEU-SAP01-X00_custom_naming.json")
            if (file.Id?.Contains("_custom_", StringComparison.OrdinalIgnoreCase) == true)
            {
                // Extract the system ID from the ID (everything before _custom_)
                int customIndex = file.Id.IndexOf("_custom_", StringComparison.OrdinalIgnoreCase);
                string systemId = file.Id.Substring(0, customIndex);

                // Store in SYSTEM folder alongside TFVARS file
                // Format: /SYSTEM/{systemId}/{filename}
                string path = $"/SYSTEM/{systemId}/{file.Id}";
                System.Diagnostics.Debug.WriteLine($"[RepositoryAppFileService.UpdateAsync] Updating custom file in SYSTEM folder: {path}");

                await _restHelper.UpdateRepo(path, content);
                return;
            }

            // For standard AppFiles (like VM-Images.json), use the default path convention
            var pathParts = file.Id?.Split('/') ?? new[] { "default", "default" };
            string partitionKey = pathParts.Length > 0 ? pathParts[0] : "default";
            string rowKey = pathParts.Length > 1 ? string.Join("/", pathParts.Skip(1)) : file.Id;

            string standardPath = _pathConvention.BuildAppFilePath(partitionKey, rowKey);
            await _restHelper.UpdateRepo(standardPath, content);
        }

        public async Task DeleteAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            // Check if this is a custom System file (e.g., "AFS-NOEU-SAP01-X00_custom_naming.json")
            if (rowKey.Contains("_custom_", StringComparison.OrdinalIgnoreCase))
            {
                // Extract the system ID from the rowKey (everything before _custom_)
                int customIndex = rowKey.IndexOf("_custom_", StringComparison.OrdinalIgnoreCase);
                string systemId = rowKey.Substring(0, customIndex);

                // Delete from SYSTEM folder
                // Format: WORKSPACES/SYSTEM/{systemId}/{filename}
                string path = $"WORKSPACES/SYSTEM/{systemId}/{rowKey}";
                System.Diagnostics.Debug.WriteLine($"[RepositoryAppFileService.DeleteAsync] Deleting custom file from SYSTEM folder: {path}");

                var deleteRequest = new RepositoryDeleteRequest
                {
                    Path = path,
                    CommitMessage = $"Delete custom file {rowKey} via SDAF App Service"
                };

                await _dataAccessProvider.DeleteFileAsync(deleteRequest);
                return;
            }

            // For standard AppFiles, use the default path convention
            string standardPath = _pathConvention.BuildAppFilePath(partitionKey, rowKey);
            var standardDeleteRequest = new RepositoryDeleteRequest
            {
                Path = standardPath,
                CommitMessage = $"Delete AppFile {rowKey} via SDAF App Service"
            };

            await _dataAccessProvider.DeleteFileAsync(standardDeleteRequest);
        }

        public async Task CreateTFVarsAsync(AppFile file)
        {
            if (file == null)
            {
                throw new ArgumentNullException(nameof(file));
            }

            // Create as a regular app file with tfvars naming
            await CreateAsync(file);

            // Also update tfvars blob for compatibility
            if (_fallbackService != null)
            {
                await _fallbackService.CreateTFVarsAsync(file);
            }
        }
    }
}

