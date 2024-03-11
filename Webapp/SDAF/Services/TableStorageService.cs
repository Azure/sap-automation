using AutomationForm.Models;
using Azure.Data.Tables;
using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using System;
using System.Threading.Tasks;

namespace AutomationForm.Services
{
  public class TableStorageService
  {
    private readonly IConfiguration _configuration;
    private readonly IDatabaseSettings _settings;
    public TableStorageService(IConfiguration configuration, IDatabaseSettings settings)
    {
      _configuration = configuration;
      _settings = settings;
    }

    public async Task<TableClient> GetTableClient(string table)
    {
      string accountName = _configuration.GetConnectionString(_settings.ConnectionStringKey).Replace("blob", "table");
      TableServiceClient serviceClient = new(
        new Uri(accountName),
        new DefaultAzureCredential());

      var tableClient = serviceClient.GetTableClient(table);
      await tableClient.CreateIfNotExistsAsync();
      return tableClient;
    }

    public async Task<BlobContainerClient> GetBlobClient(string container)
    {
      string accountName = _configuration.GetConnectionString(_settings.ConnectionStringKey);
      BlobServiceClient serviceClient = new(
        new Uri(accountName),
        new DefaultAzureCredential());

      var blobClient = serviceClient.GetBlobContainerClient(container);
      await blobClient.CreateIfNotExistsAsync();
      return blobClient;
    }
  }
}
