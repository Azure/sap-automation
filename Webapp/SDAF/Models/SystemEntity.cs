using Azure;
using Azure.Data.Tables;
using System;
using System.Text.Json;

namespace AutomationForm.Models
{
  public class SystemEntity : ITableEntity
  {
    public SystemEntity() { }

    public SystemEntity(SystemModel system)
    {
      RowKey = system.Id;
      PartitionKey = system.environment;
      IsDefault = system.IsDefault;
      System = JsonSerializer.Serialize(system, new JsonSerializerOptions() { });
    }

    public string RowKey { get; set; } = default!;

    public string PartitionKey { get; set; } = default!;

    public ETag ETag { get; set; } = default!;

    public DateTimeOffset? Timestamp { get; set; } = default!;

    public string System { get; set; }

    public bool IsDefault { get; set; } = false;
  }
}
