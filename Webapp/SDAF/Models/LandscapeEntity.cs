using Azure;
using Azure.Data.Tables;
using System;
using System.Text.Json;

namespace AutomationForm.Models
{
  public class LandscapeEntity : ITableEntity
  {
    public LandscapeEntity() { }
    public LandscapeEntity(LandscapeModel landscape)
    {
      RowKey = landscape.Id;
      PartitionKey = landscape.environment;
      IsDefault = landscape.IsDefault;
      Landscape = JsonSerializer.Serialize(landscape, new JsonSerializerOptions() { });
    }

    public string RowKey { get; set; } = default!;

    public string PartitionKey { get; set; } = default!;

    public ETag ETag { get; set; } = default!;

    public DateTimeOffset? Timestamp { get; set; } = default!;

    public string Landscape { get; set; }

    public bool IsDefault { get; set; } = false;
  }
}
