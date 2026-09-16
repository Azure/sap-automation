// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SDAFWebApp.Controllers;
using SDAFWebApp.Models;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    /// <summary>
    /// Implements repository data access with support for both ADO and GitHub.
    /// Wraps RestHelper methods and applies persistence mode configuration.
    /// </summary>
    public class RepositoryDataAccessProvider : IRepositoryDataAccessProvider
    {
        private readonly RestHelper _restHelper;
        private readonly IRepositoryPathConvention _pathConvention;
        private readonly RepositoryPersistenceSettings _settings;
        private readonly ILogger<RepositoryDataAccessProvider> _logger;
        private readonly string _platform;

        public RepositoryPersistenceMode PersistenceMode => _settings.GetPersistenceMode();
        public string Platform => _platform;

        public RepositoryDataAccessProvider(
            IConfiguration configuration,
            IRepositoryPathConvention pathConvention,
            IOptions<RepositoryPersistenceSettings> persistenceSettings,
            ILogger<RepositoryDataAccessProvider> logger)
        {
            _pathConvention = pathConvention ?? throw new ArgumentNullException(nameof(pathConvention));
            _settings = persistenceSettings.Value ?? new RepositoryPersistenceSettings();
            _logger = logger;

            // Determine platform from environment or config
            _platform = Environment.GetEnvironmentVariable("DEVOPS_PLATFORM")?.ToLower()
                ?? configuration["DEVOPS_PLATFORM"]?.ToLower()
                ?? "ado";

            // Create RestHelper with the configured platform
            _restHelper = new RestHelper(configuration, _platform);

            if (_settings.EnableRepositoryLogging)
            {
                _logger?.LogInformation(
                    "RepositoryDataAccessProvider initialized: Platform={Platform}, Mode={Mode}",
                    _platform, PersistenceMode);
            }
        }

        public async Task<RepositoryFileResponse> GetFileAsync(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new ArgumentException("Path cannot be null or empty.", nameof(path));
            }

            try
            {
                if (_settings.EnableRepositoryLogging)
                {
                    _logger?.LogInformation(
                        "Reading repository file: Path={Path}, Platform={Platform}",
                        path, _platform);
                }

                var response = await _restHelper.GetRepositoryFileAsync(path);

                if (_settings.EnableRepositoryLogging)
                {
                    _logger?.LogInformation(
                        "Successfully read repository file: Path={Path}, Size={Size}",
                        path, response.ContentBytes?.Length ?? response.Content?.Length ?? 0);
                }

                return response;
            }
            catch (RepositoryOperationException ex)
            {
                _logger?.LogWarning(
                    ex,
                    "Repository operation failed: Path={Path}, Category={Category}, Transient={Transient}",
                    path, ex.ErrorCategory, ex.IsTransient);
                throw;
            }
        }

        public async Task<RepositoryListResponse> ListFilesAsync(string directoryPath)
        {
            if (string.IsNullOrWhiteSpace(directoryPath))
            {
                throw new ArgumentException("Directory path cannot be null or empty.", nameof(directoryPath));
            }

            try
            {
                if (_settings.EnableRepositoryLogging)
                {
                    _logger?.LogInformation(
                        "Listing repository files: DirectoryPath={DirectoryPath}, Platform={Platform}",
                        directoryPath, _platform);
                }

                var response = await _restHelper.ListRepositoryFilesAsync(directoryPath);

                if (_settings.EnableRepositoryLogging)
                {
                    _logger?.LogInformation(
                        "Successfully listed repository files: DirectoryPath={DirectoryPath}, Count={Count}, Items={Items}",
                        directoryPath, response.Count, string.Join(", ", response.Items.Select(i => i.Path)));
                }

                return response;
            }
            catch (RepositoryOperationException ex)
            {
                _logger?.LogWarning(
                    ex,
                    "Repository list operation failed: DirectoryPath={DirectoryPath}, Category={Category}",
                    directoryPath, ex.ErrorCategory);
                throw;
            }
        }

        public async Task DeleteFileAsync(RepositoryDeleteRequest request)
        {
            if (request == null)
            {
                throw new ArgumentNullException(nameof(request));
            }

            if (string.IsNullOrWhiteSpace(request.Path))
            {
                throw new ArgumentException("Path cannot be null or empty.", nameof(request));
            }

            try
            {
                if (_settings.EnableRepositoryLogging)
                {
                    _logger?.LogInformation(
                        "Deleting repository file: Path={Path}, Message={Message}, Platform={Platform}",
                        request.Path, request.CommitMessage, _platform);
                }

                await _restHelper.DeleteRepositoryFileAsync(request);

                if (_settings.EnableRepositoryLogging)
                {
                    _logger?.LogInformation(
                        "Successfully deleted repository file: Path={Path}",
                        request.Path);
                }
            }
            catch (RepositoryOperationException ex)
            {
                _logger?.LogWarning(
                    ex,
                    "Repository delete operation failed: Path={Path}, Category={Category}",
                    request.Path, ex.ErrorCategory);
                throw;
            }
        }

        public async Task<bool> FileExistsAsync(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new ArgumentException("Path cannot be null or empty.", nameof(path));
            }

            try
            {
                var exists = await _restHelper.RepositoryFileExistsAsync(path);

                if (_settings.EnableRepositoryLogging && !exists)
                {
                    _logger?.LogDebug(
                        "Repository file does not exist: Path={Path}, Platform={Platform}",
                        path, _platform);
                }

                return exists;
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(
                    ex,
                    "Error checking file existence: Path={Path}",
                    path);
                return false;
            }
        }
    }
}
