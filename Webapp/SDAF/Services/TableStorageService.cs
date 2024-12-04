using SDAFWebApp.Models;
using Azure.Data.Tables;
using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using System;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
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

      string devops_authentication = Environment.GetEnvironmentVariable("AUTHENTICATION_TYPE");
      string accountName = _configuration.GetConnectionString(_settings.ConnectionStringKey).Replace("blob", "table");
      DefaultAzureCredential creds = new DefaultAzureCredential(new DefaultAzureCredentialOptions
      {
        TenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID"),
        ManagedIdentityClientId = Environment.GetEnvironmentVariable("OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID")
      });
      if (devops_authentication == "PAT")
      {
        creds = new DefaultAzureCredential();
      }
      TableServiceClient serviceClient = new(
        new Uri(accountName), creds
       );

      var tableClient = serviceClient.GetTableClient(table);
      await tableClient.CreateIfNotExistsAsync();
      return tableClient;
    }

    public async Task<BlobContainerClient> GetBlobClient(string container)
    {
      string accountName = _configuration.GetConnectionString(_settings.ConnectionStringKey);
      string devops_authentication = Environment.GetEnvironmentVariable("AUTHENTICATION_TYPE");

      DefaultAzureCredential creds = new DefaultAzureCredential(new DefaultAzureCredentialOptions
      {
        TenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID"),
        ManagedIdentityClientId = Environment.GetEnvironmentVariable("OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID")
      });
      if (devops_authentication == "PAT")
      {
        creds = new DefaultAzureCredential();
      }

      BlobServiceClient serviceClient = new(
        new Uri(accountName),
        creds);

      var blobClient = serviceClient.GetBlobContainerClient(container);
      await blobClient.CreateIfNotExistsAsync();
      return blobClient;
    }
  }
}
