// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.Extensions.Options;
using SDAFWebApp.Models;
using System;
using System.IO;

namespace SDAFWebApp.Services
{
    public interface IRepositoryPathConvention
    {
        string BuildLandscapePath(string partitionKey, string rowKey);
        string BuildSystemPath(string partitionKey, string rowKey);
        string BuildAppFilePath(string partitionKey, string rowKey);
        (string partitionKey, string rowKey) ParseLandscapePath(string path);
        (string partitionKey, string rowKey) ParseSystemPath(string path);
        (string partitionKey, string rowKey) ParseAppFilePath(string path);
    }

    public class RepositoryPathConvention : IRepositoryPathConvention
    {
        private readonly RepositoryPathSettings _paths;

        public RepositoryPathConvention(IOptions<RepositoryPersistenceSettings> persistenceSettings)
        {
            _paths = persistenceSettings.Value.Paths ?? new RepositoryPathSettings();
        }

        public string BuildLandscapePath(string partitionKey, string rowKey)
        {
            return BuildJsonObjectPath(_paths.Landscapes, partitionKey, rowKey);
        }

        public string BuildSystemPath(string partitionKey, string rowKey)
        {
            return BuildJsonObjectPath(_paths.Systems, partitionKey, rowKey);
        }

        public string BuildAppFilePath(string partitionKey, string rowKey)
        {
            return CombinePath(_paths.Root, _paths.AppFiles, SanitizeSegment(partitionKey), SanitizeSegment(rowKey));
        }

        public (string partitionKey, string rowKey) ParseLandscapePath(string path)
        {
            return ParseJsonObjectPath(path, _paths.Landscapes);
        }

        public (string partitionKey, string rowKey) ParseSystemPath(string path)
        {
            return ParseJsonObjectPath(path, _paths.Systems);
        }

        public (string partitionKey, string rowKey) ParseAppFilePath(string path)
        {
            string normalizedPath = NormalizePath(path);
            string prefix = NormalizePath(CombinePath(_paths.Root, _paths.AppFiles));

            if (!normalizedPath.StartsWith(prefix + "/", StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException($"Path '{path}' is not in expected app file scope '{prefix}/<partition>/<row>'.", nameof(path));
            }

            string relativePath = normalizedPath[(prefix.Length + 1)..];
            string[] parts = relativePath.Split('/');
            if (parts.Length < 2)
            {
                throw new ArgumentException($"Path '{path}' does not contain expected '<partition>/<row>' structure.", nameof(path));
            }

            string partitionKey = parts[0];
            string rowKey = string.Join("/", parts, 1, parts.Length - 1);
            return (partitionKey, rowKey);
        }

        private string BuildJsonObjectPath(string objectRoot, string partitionKey, string rowKey)
        {
            return CombinePath(_paths.Root, objectRoot, SanitizeSegment(partitionKey), SanitizeSegment(rowKey) + ".json");
        }

        private (string partitionKey, string rowKey) ParseJsonObjectPath(string path, string objectRoot)
        {
            string normalizedPath = NormalizePath(path);
            string prefix = NormalizePath(CombinePath(_paths.Root, objectRoot));

            if (!normalizedPath.StartsWith(prefix + "/", StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException($"Path '{path}' is not in expected scope '{prefix}/<partition>/<row>.json'.", nameof(path));
            }

            string relativePath = normalizedPath[(prefix.Length + 1)..];
            string[] parts = relativePath.Split('/');
            if (parts.Length != 2)
            {
                throw new ArgumentException($"Path '{path}' does not contain expected '<partition>/<row>.json' structure.", nameof(path));
            }

            string partitionKey = parts[0];
            string fileName = parts[1];
            if (!fileName.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException($"Path '{path}' does not end with '.json'.", nameof(path));
            }

            string rowKey = fileName[..^5];
            return (partitionKey, rowKey);
        }

        private static string CombinePath(params string[] segments)
        {
            return NormalizePath(string.Join("/", Array.FindAll(segments, segment => !string.IsNullOrWhiteSpace(segment))));
        }

        private static string NormalizePath(string path)
        {
            return path.Replace('\\', '/').Trim('/');
        }

        private static string SanitizeSegment(string segment)
        {
            if (string.IsNullOrWhiteSpace(segment))
            {
                throw new ArgumentException("Path segment cannot be null, empty, or whitespace.", nameof(segment));
            }

            if (segment.Contains("..", StringComparison.Ordinal) || segment.Contains('/') || segment.Contains('\\'))
            {
                throw new ArgumentException("Path segment cannot contain path traversal or separators.", nameof(segment));
            }

            foreach (char c in Path.GetInvalidFileNameChars())
            {
                if (segment.Contains(c, StringComparison.Ordinal))
                {
                    throw new ArgumentException($"Path segment contains invalid file name character '{c}'.", nameof(segment));
                }
            }

            return segment;
        }
    }
}
