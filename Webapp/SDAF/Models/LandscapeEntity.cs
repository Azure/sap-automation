// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Azure;
using Azure.Data.Tables;
using System;
using System.Text.Json;

namespace SDAFWebApp.Models
{
    public class LandscapeEntity : ITableEntity
    {
        public LandscapeEntity() { }
        public LandscapeEntity(LandscapeModel landscape)
            : this(landscape, null)
        {
        }

        public LandscapeEntity(LandscapeModel landscape, string backend)
        {
            RowKey = landscape.Id;
            PartitionKey = IsRepositoryBackend(backend) ? landscape.Id : landscape.environment;
            IsDefault = landscape.IsDefault;
            Landscape = JsonSerializer.Serialize(landscape, new JsonSerializerOptions() { });
        }

        private static bool IsRepositoryBackend(string backend)
        {
            return string.Equals(backend, "ado", StringComparison.OrdinalIgnoreCase)
                || string.Equals(backend, "github", StringComparison.OrdinalIgnoreCase);
        }

        public string RowKey { get; set; } = default!;

        public string PartitionKey { get; set; } = default!;

        public ETag ETag { get; set; } = default!;

        public DateTimeOffset? Timestamp { get; set; } = default!;

        public string Landscape { get; set; }

        public bool IsDefault { get; set; } = false;
    }
}
