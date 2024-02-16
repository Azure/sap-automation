using Azure;
using Azure.Data.Tables;
using System;

namespace AutomationForm.Models
{
  public class AppFileEntity : ITableEntity
  {
    public AppFileEntity() { }

    public AppFileEntity(string id, string uri)
    {
      RowKey = id;
      PartitionKey = id[..id.IndexOf('-')];
      BlobUri = uri;
    }

    public string RowKey { get; set; } = default!;

    public string PartitionKey { get; set; } = default!;

    public ETag ETag { get; set; } = default!;

    public DateTimeOffset? Timestamp { get; set; } = default!;

    public string BlobUri { get; set; }
  }
}
