// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;

namespace SDAFWebApp.Models
{
    /// <summary>
    /// Configuration for repository-backed persistence (GitHub/ADO).
    /// Controls whether to use repository, storage, or both with fallback.
    /// </summary>
    public class RepositoryPersistenceSettings
    {
        public const string SectionName = "RepositoryPersistence";
        public const string ModeEnvironmentVariable = "REPOSITORY_PERSISTENCE_MODE";

        private string _mode = "RepositoryPreferredWithStorageFallback";

        /// <summary>
        /// Persistence mode: RepositoryPreferredWithStorageFallback (default), RepositoryOnly, or StorageOnly.
        /// Reads from environment variable REPOSITORY_PERSISTENCE_MODE if set, otherwise uses appsettings value.
        /// </summary>
        public string Mode
        {
            get
            {
                var envMode = Environment.GetEnvironmentVariable(ModeEnvironmentVariable);
                return !string.IsNullOrWhiteSpace(envMode) ? envMode : _mode;
            }
            set { _mode = value; }
        }

        /// <summary>
        /// Path configuration for repository-backed objects (landscapes, systems, files).
        /// </summary>
        public RepositoryPathSettings Paths { get; set; } = new();

        /// <summary>
        /// Whether to enable structured logging for repository operations.
        /// </summary>
        public bool EnableRepositoryLogging { get; set; } = true;

        /// <summary>
        /// Timeout in seconds for repository API calls (default 30s).
        /// </summary>
        public int RepositoryTimeoutSeconds { get; set; } = 30;

        /// <summary>
        /// Gets the parsed persistence mode enum value.
        /// </summary>
        public RepositoryPersistenceMode GetPersistenceMode()
        {
            if (Enum.TryParse<RepositoryPersistenceMode>(Mode, true, out var result))
            {
                return result;
            }
            return RepositoryPersistenceMode.RepositoryPreferredWithStorageFallback;
        }
    }

    /// <summary>
    /// Path configuration for repository-backed storage objects.
    /// Defines where landscapes, systems, and app files are stored in the repository structure.
    /// </summary>
    public class RepositoryPathSettings
    {
        /// <summary>
        /// Root directory in repository (e.g., "WORKSPACES").
        /// </summary>
        public string Root { get; set; } = "WORKSPACES";

        /// <summary>
        /// Subdirectory for landscapes (e.g., "LANDSCAPE").
        /// </summary>
        public string Landscapes { get; set; } = "LANDSCAPE";

        /// <summary>
        /// Subdirectory for systems (e.g., "SYSTEM").
        /// </summary>
        public string Systems { get; set; } = "SYSTEM";

        /// <summary>
        /// Subdirectory for application files (e.g., "APPDATA/FILES"). Leave empty to disable.
        /// </summary>
        public string AppFiles { get; set; } = "";
    }
}
