using Azure;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Data.Tables;

namespace AutomationForm.Models
{
    public class AppFileEntity : ITableEntity
    {
        public AppFileEntity() { }

        public AppFileEntity(string id, string uri)
        {
            RowKey = id;
            PartitionKey = id.Substring(0, id.IndexOf('-'));
            BlobUri = uri;
        }

        public string RowKey { get; set; } = default!;

        public string PartitionKey { get; set; } = default!;

        public ETag ETag { get; set; } = default!;

        public DateTimeOffset? Timestamp { get; set; } = default!;

        public string BlobUri { get; set; }
    }
}
