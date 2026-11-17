// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;

namespace SDAFWebApp.Models
{
    /// <summary>
    /// Represents the persistence mode for repository-backed storage.
    /// </summary>
    public enum RepositoryPersistenceMode
    {
        /// <summary>
        /// Use repository (GitHub/ADO) with Azure Storage as fallback (default, safe mode).
        /// </summary>
        RepositoryPreferredWithStorageFallback,

        /// <summary>
        /// Use repository only; fail if repository operations fail.
        /// </summary>
        RepositoryOnly,

        /// <summary>
        /// Use Azure Storage only; repository backed persistence disabled.
        /// </summary>
        StorageOnly
    }

    /// <summary>
    /// Response from repository read operations.
    /// </summary>
    public class RepositoryFileResponse
    {
        /// <summary>
        /// File path in repository.
        /// </summary>
        public string Path { get; set; }

        /// <summary>
        /// File content as string (for text files like JSON).
        /// </summary>
        public string Content { get; set; }

        /// <summary>
        /// File content as bytes (for binary files).
        /// </summary>
        public byte[] ContentBytes { get; set; }

        /// <summary>
        /// Commit SHA or latest commit reference (for concurrency control).
        /// </summary>
        public string CommitSha { get; set; }

        /// <summary>
        /// Timestamp of last commit.
        /// </summary>
        public DateTimeOffset? LastModified { get; set; }

        /// <summary>
        /// Whether file exists in repository.
        /// </summary>
        public bool Exists { get; set; } = true;
    }

    /// <summary>
    /// Response from repository list operations.
    /// </summary>
    public class RepositoryListResponse
    {
        /// <summary>
        /// List of files found under the directory.
        /// </summary>
        public List<RepositoryListItem> Items { get; set; } = new();

        /// <summary>
        /// Total count of items (may be capped).
        /// </summary>
        public int Count => Items.Count;
    }

    /// <summary>
    /// Represents a single item in a repository list response.
    /// </summary>
    public class RepositoryListItem
    {
        /// <summary>
        /// File path in repository.
        /// </summary>
        public string Path { get; set; }

        /// <summary>
        /// File name (last segment of path).
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Whether this is a directory (folder).
        /// </summary>
        public bool IsDirectory { get; set; }

        /// <summary>
        /// Size in bytes (for files).
        /// </summary>
        public long? Size { get; set; }

        /// <summary>
        /// Last commit SHA for this item.
        /// </summary>
        public string CommitSha { get; set; }

        /// <summary>
        /// Last modified timestamp.
        /// </summary>
        public DateTimeOffset? LastModified { get; set; }
    }

    /// <summary>
    /// Request body for repository delete operations (tracks intent for logging).
    /// </summary>
    public class RepositoryDeleteRequest
    {
        /// <summary>
        /// File path to delete.
        /// </summary>
        public string Path { get; set; }

        /// <summary>
        /// Commit message for deletion.
        /// </summary>
        public string CommitMessage { get; set; } = "Delete file via SDAF App Service";

        /// <summary>
        /// Expected commit SHA (for optimistic concurrency on GitHub).
        /// </summary>
        public string ExpectedCommitSha { get; set; }
    }

    /// <summary>
    /// Exception for repository operations with categorized error semantics.
    /// </summary>
    public class RepositoryOperationException : Exception
    {
        /// <summary>
        /// Error category for retry/fallback logic.
        /// </summary>
        public RepositoryErrorCategory ErrorCategory { get; set; }

        /// <summary>
        /// HTTP status code if applicable.
        /// </summary>
        public int? HttpStatusCode { get; set; }

        /// <summary>
        /// Whether this error is transient (retryable).
        /// </summary>
        public bool IsTransient { get; set; }

        public RepositoryOperationException(string message, RepositoryErrorCategory category, int? statusCode = null, bool isTransient = false, Exception innerException = null)
            : base(message, innerException)
        {
            ErrorCategory = category;
            HttpStatusCode = statusCode;
            IsTransient = isTransient;
        }
    }

    /// <summary>
    /// Categories of repository operation errors.
    /// </summary>
    public enum RepositoryErrorCategory
    {
        /// <summary>
        /// File or resource not found.
        /// </summary>
        NotFound,

        /// <summary>
        /// Authentication or authorization failure.
        /// </summary>
        AuthenticationError,

        /// <summary>
        /// Concurrency conflict (e.g., branch moved).
        /// </summary>
        Conflict,

        /// <summary>
        /// Transient error (network, timeout, service unavailable).
        /// </summary>
        TransientError,

        /// <summary>
        /// Invalid request parameters.
        /// </summary>
        ValidationError,

        /// <summary>
        /// Unexpected or unclassified error.
        /// </summary>
        Unknown
    }
}
