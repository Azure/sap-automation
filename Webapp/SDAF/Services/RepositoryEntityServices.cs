// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using SDAFWebApp.Controllers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

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
            RepositoryListResponse listResponse;

            try
            {
                // List all partition folders in the root directory (use recursionLevel=1 to only get immediate children)
                listResponse = await _dataAccessProvider.ListFilesAsync(GetEntityRootPath());
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                return result;
            }

            foreach (var item in listResponse.Items)
            {
                // Look for partition folders (folders that are not the root LANDSCAPE/SYSTEM folder itself)
                if (item.IsDirectory && item.Path.Contains("/") &&
                    !item.Path.EndsWith("LANDSCAPE", StringComparison.OrdinalIgnoreCase) &&
                    !item.Path.EndsWith("SYSTEM", StringComparison.OrdinalIgnoreCase))
                {
                    var parts = item.Path.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
                    var partitionKey = parts[parts.Length - 1];
                    var partitionResults = await GetAllAsync(partitionKey, returnEmptyWhenMissing: false);
                    result.AddRange(partitionResults);
                }
            }

            return result;
        }

        public async Task<List<T>> GetAllAsync(string partitionKey)
        {
            return await GetAllAsync(partitionKey, returnEmptyWhenMissing: true);
        }

        private async Task<List<T>> GetAllAsync(string partitionKey, bool returnEmptyWhenMissing)
        {
            var result = new List<T>();
            RepositoryListResponse listResponse;

            try
            {
                string partitionPath = GetPartitionPath(partitionKey);
                listResponse = await _dataAccessProvider.ListFilesAsync(partitionPath);
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                if (returnEmptyWhenMissing)
                {
                    return result;
                }

                throw;
            }

            foreach (var item in listResponse.Items)
            {
                if (!item.IsDirectory && item.Path.EndsWith(".tfvars", StringComparison.OrdinalIgnoreCase))
                {
                    var fileResponse = await _dataAccessProvider.GetFileAsync(item.Path);
                    var entity = DeserializeTfvars(fileResponse.Content, partitionKey);
                    result.Add(entity);
                }
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
            var allEntities = await GetAllAsync();
            return allEntities.FirstOrDefault(e => IsDefault(e));
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
        public RepositoryLandscapeService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            IDatabaseSettings databaseSettings,
            RestHelper restHelper)
            : base(dataAccessProvider, pathConvention, restHelper)
        {
            _databaseSettings = databaseSettings ?? throw new ArgumentNullException(nameof(databaseSettings));
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
            if (string.IsNullOrEmpty(content))
            {
                throw new RepositoryOperationException(
                    "The workload-zone TFVars file is empty.",
                    RepositoryErrorCategory.ValidationError);
            }

            try
            {
                // Convert TFVARS HCL to JSON format
                string jsonContent = Helper.TfvarToJson(content);
                // Deserialize JSON to LandscapeModel with case-insensitive property matching
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var landscape = JsonSerializer.Deserialize<LandscapeModel>(jsonContent, options) ?? new LandscapeModel();

                // If Id is not set from TFVARS, use partition key
                if (string.IsNullOrEmpty(landscape.Id))
                {
                    landscape.Id = partitionKey;
                }

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
                throw new RepositoryOperationException(
                    "The workload-zone TFVars file could not be parsed.",
                    RepositoryErrorCategory.ValidationError,
                    innerException: ex);
            }
        }

        protected override string SerializeTfvars(LandscapeEntity entity)
        {
            // Deserialize the Landscape JSON back to LandscapeModel, then convert to TFVARS
            var landscape = JsonSerializer.Deserialize<LandscapeModel>(entity.Landscape);
            return Helper.ConvertToTerraform(landscape);
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
            try
            {
                var fileResponse = await _dataAccessProvider.GetFileAsync(tfvarsPath);
                return DeserializeTfvars(fileResponse.Content, partitionKey);
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
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

        }
    }

    /// <summary>
    /// Repository-backed implementation for SystemEntity.
    /// Stores systems as JSON documents in WORKSPACES/SYSTEM/{environment}/{id}.json
    /// </summary>
    public class RepositorySystemService : RepositoryJsonEntityService<SystemEntity>
    {
        private readonly IDatabaseSettings _databaseSettings;
        public RepositorySystemService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            IDatabaseSettings databaseSettings,
            RestHelper restHelper)
            : base(dataAccessProvider, pathConvention, restHelper)
        {
            _databaseSettings = databaseSettings ?? throw new ArgumentNullException(nameof(databaseSettings));
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
            if (string.IsNullOrEmpty(content))
            {
                throw new RepositoryOperationException(
                    "The system TFVars file is empty.",
                    RepositoryErrorCategory.ValidationError);
            }

            try
            {
                // Convert TFVARS HCL to JSON format
                string jsonContent = Helper.TfvarToJson(content);
                // Deserialize JSON to SystemModel with case-insensitive property matching
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var system = JsonSerializer.Deserialize<SystemModel>(jsonContent, options) ?? new SystemModel();

                // If Id is not set from TFVARS, use partition key
                if (string.IsNullOrEmpty(system.Id))
                {
                    system.Id = partitionKey;
                }

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
                throw new RepositoryOperationException(
                    "The system TFVars file could not be parsed.",
                    RepositoryErrorCategory.ValidationError,
                    innerException: ex);
            }
        }

        protected override string SerializeTfvars(SystemEntity entity)
        {
            // Deserialize the System JSON back to SystemModel, then convert to TFVARS
            var system = JsonSerializer.Deserialize<SystemModel>(entity.System);
            return Helper.ConvertToTerraform(system);
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
            try
            {
                var fileResponse = await _dataAccessProvider.GetFileAsync(tfvarsPath);
                return DeserializeTfvars(fileResponse.Content, partitionKey);
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
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
        public RepositoryAppFileService(
            IRepositoryDataAccessProvider dataAccessProvider,
            IRepositoryPathConvention pathConvention,
            RestHelper restHelper,
            IDatabaseSettings databaseSettings)
        {
            _dataAccessProvider = dataAccessProvider ?? throw new ArgumentNullException(nameof(dataAccessProvider));
            _pathConvention = pathConvention ?? throw new ArgumentNullException(nameof(pathConvention));
            _restHelper = restHelper ?? throw new ArgumentNullException(nameof(restHelper));
            _databaseSettings = databaseSettings ?? throw new ArgumentNullException(nameof(databaseSettings));
        }

        public async Task<List<AppFile>> GetNAsync(int n)
        {
            var all = await GetAllAsync();
            return all.Take(n).ToList();
        }

        public async Task<List<AppFile>> GetAllAsync()
        {
            return await GetFilesAsync(_pathConvention.GetAppFilesRootPath(), null);
        }

        public async Task<List<AppFile>> GetAllAsync(string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("PartitionKey cannot be null or empty.", nameof(partitionKey));
            }

            return await GetFilesAsync(_pathConvention.GetAppFilePartitionPath(partitionKey), partitionKey);
        }

        private async Task<List<AppFile>> GetFilesAsync(string directoryPath, string expectedPartitionKey)
        {
            var result = new List<AppFile>();
            RepositoryListResponse response;

            try
            {
                response = await _dataAccessProvider.ListFilesAsync(directoryPath);
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                return result;
            }

            foreach (var item in response.Items.Where(item => !item.IsDirectory))
            {
                var (partitionKey, rowKey) = _pathConvention.ParseAppFilePath(item.Path);
                if (expectedPartitionKey != null &&
                    !string.Equals(partitionKey, expectedPartitionKey, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var fileResponse = await _dataAccessProvider.GetFileAsync(item.Path);
                byte[] content = fileResponse.ContentBytes
                    ?? System.Text.Encoding.UTF8.GetBytes(fileResponse.Content ?? string.Empty);
                result.Add(new AppFile
                {
                    Id = rowKey,
                    Content = content,
                    UntrustedName = rowKey,
                    Size = content.LongLength
                });
            }

            return result;
        }

        public async Task<AppFile> GetByIdAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            AppFileIdentifier parsed = IdentifierParser.ParseAppFile(rowKey);
            if (parsed.Kind == AppFileKind.CustomNaming || parsed.Kind == AppFileKind.CustomSizes)
            {
                if (!string.Equals(partitionKey, parsed.PartitionKey, StringComparison.OrdinalIgnoreCase) &&
                    !string.Equals(partitionKey, parsed.ObjectId, StringComparison.OrdinalIgnoreCase))
                {
                    throw new ArgumentException("Partition key does not match the custom file name.", nameof(partitionKey));
                }

                string path = _pathConvention.BuildSystemArtifactPath(parsed.ObjectId, parsed.FileName);

                var fileResponse = await _dataAccessProvider.GetFileAsync(path);
                return new AppFile
                {
                    Id = rowKey,
                    Content = fileResponse.ContentBytes ?? System.Text.Encoding.UTF8.GetBytes(fileResponse.Content)
                };
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

            AppFileIdentifier parsed = IdentifierParser.ParseAppFile(file.Id);
            if (parsed.Kind == AppFileKind.CustomNaming || parsed.Kind == AppFileKind.CustomSizes)
            {
                string path = _pathConvention.BuildSystemArtifactPath(parsed.ObjectId, parsed.FileName);
                path = StripWorkspacePrefix(path);
                await _restHelper.UpdateRepo(path, content);
                return;
            }

            string standardPath = _pathConvention.BuildAppFilePath(parsed.PartitionKey, parsed.FileName);
            await _restHelper.UpdateRepo(standardPath, content);
        }

        public async Task UpdateAsync(AppFile file)
        {
            if (file == null)
            {
                throw new ArgumentNullException(nameof(file));
            }

            string content = System.Text.Encoding.UTF8.GetString(file.Content ?? Array.Empty<byte>());

            AppFileIdentifier parsed = IdentifierParser.ParseAppFile(file.Id);
            if (parsed.Kind == AppFileKind.CustomNaming || parsed.Kind == AppFileKind.CustomSizes)
            {
                string path = StripWorkspacePrefix(
                    _pathConvention.BuildSystemArtifactPath(parsed.ObjectId, parsed.FileName));
                await _restHelper.UpdateRepo(path, content);
                return;
            }

            string standardPath = _pathConvention.BuildAppFilePath(parsed.PartitionKey, parsed.FileName);
            await _restHelper.UpdateRepo(standardPath, content);
        }

        private static string StripWorkspacePrefix(string path)
        {
            const string prefix = "WORKSPACES/";
            return path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                ? path[prefix.Length..]
                : path;
        }

        public async Task DeleteAsync(string rowKey, string partitionKey)
        {
            if (string.IsNullOrWhiteSpace(rowKey) || string.IsNullOrWhiteSpace(partitionKey))
            {
                throw new ArgumentException("RowKey and PartitionKey cannot be null or empty.");
            }

            // Check if this is a custom System file (e.g., "AFS-NOEU-SAP01-X00_custom_naming.json")
            AppFileIdentifier parsed = IdentifierParser.ParseAppFile(rowKey);
            if (parsed.Kind == AppFileKind.CustomNaming || parsed.Kind == AppFileKind.CustomSizes)
            {
                string path = _pathConvention.BuildSystemArtifactPath(parsed.ObjectId, parsed.FileName);

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

        }
    }
}
