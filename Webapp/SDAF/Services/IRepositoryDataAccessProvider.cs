// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    /// <summary>
    /// Provides repository read/list/delete operations for both ADO and GitHub.
    /// Used as a data-access layer for repository-backed persistence.
    /// </summary>
    public interface IRepositoryDataAccessProvider
    {
        /// <summary>
        /// Gets the persistence mode (RepositoryPreferred, RepositoryOnly, or StorageOnly).
        /// </summary>
        RepositoryPersistenceMode PersistenceMode { get; }

        /// <summary>
        /// Gets the configured DevOps platform (ado or github).
        /// </summary>
        string Platform { get; }

        /// <summary>
        /// Reads file content from repository.
        /// </summary>
        /// <param name="path">File path in repository.</param>
        /// <returns>RepositoryFileResponse with content and metadata, or throws RepositoryOperationException.</returns>
        Task<RepositoryFileResponse> GetFileAsync(string path);

        /// <summary>
        /// Lists files recursively under a directory path in repository.
        /// </summary>
        /// <param name="directoryPath">Directory path to list (e.g., "WORKSPACES/LANDSCAPE/dev").</param>
        /// <returns>RepositoryListResponse with items found.</returns>
        Task<RepositoryListResponse> ListFilesAsync(string directoryPath);

        /// <summary>
        /// Deletes a file from repository (creates a commit).
        /// </summary>
        /// <param name="request">RepositoryDeleteRequest with path and metadata.</param>
        /// <returns>Task that completes on successful deletion, throws RepositoryOperationException on failure.</returns>
        Task DeleteFileAsync(RepositoryDeleteRequest request);

        /// <summary>
        /// Checks if a file exists in repository (optimized path check without full content read).
        /// </summary>
        /// <param name="path">File path to check.</param>
        /// <returns>True if file exists, false otherwise.</returns>
        Task<bool> FileExistsAsync(string path);
    }
}
