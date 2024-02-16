using AutomationForm.Models;
using Azure;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Services
{
  public class SystemService : ITableStorageService<SystemEntity>
  {
    private readonly TableClient client;
    private readonly BlobContainerClient tfvarsBlobContainerClient;

    public SystemService(TableStorageService tableStorageService, IDatabaseSettings settings)
    {
      client = tableStorageService.GetTableClient(settings.SystemCollectionName).Result;
      tfvarsBlobContainerClient = tableStorageService.GetBlobClient(settings.TfVarBlobCollectionName).Result;
    }

    public async Task<List<SystemEntity>> GetNAsync(int n)
    {
      return await client.QueryAsync<SystemEntity>(entity => true, n).ToListAsync();
    }

    public async Task<List<SystemEntity>> GetAllAsync()
    {
      return await client.QueryAsync<SystemEntity>(entity => true).ToListAsync();
    }

    public async Task<List<SystemEntity>> GetAllAsync(string partitionKey)
    {
      return await client.QueryAsync<SystemEntity>(entity => entity.PartitionKey == partitionKey).ToListAsync();
    }

    public async Task<SystemEntity> GetByIdAsync(string rowKey, string partitionKey)
    {
      return await client.GetEntityAsync<SystemEntity>(partitionKey, rowKey);
    }

    public async Task<SystemEntity> GetDefault()
    {
      AsyncPageable<SystemEntity> defaults = client.QueryAsync<SystemEntity>(entity => entity.IsDefault);
      return await defaults.FirstOrDefaultAsync();
    }

    public Task CreateAsync(SystemEntity entity)
    {
      return client.AddEntityAsync(entity);
    }

    public Task UpdateAsync(SystemEntity entity)
    {
      return client.UpsertEntityAsync(entity, TableUpdateMode.Merge);
    }

    public Task DeleteAsync(string rowKey, string partitionKey)
    {
      return client.DeleteEntityAsync(partitionKey, rowKey);
    }

    public Task CreateTFVarsAsync(AppFile file)
    {
      BlobClient blobClient = tfvarsBlobContainerClient.GetBlobClient(file.Id);
      return blobClient.UploadAsync(new BinaryData(file.Content), overwrite: blobClient.Exists());
    }

  }
}
