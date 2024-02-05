using AutomationForm.Models;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace AutomationForm.Services
{
  public class AppFileService : ITableStorageService<AppFile>
  {
    private readonly TableClient client;
    private readonly BlobContainerClient blobContainerClient;
    public AppFileService(TableStorageService tableStorageService, IDatabaseSettings settings)
    {
      client = tableStorageService.GetTableClient(settings.AppFileCollectionName).Result;
      blobContainerClient = tableStorageService.GetBlobClient(settings.AppFileBlobCollectionName).Result;
    }

    public async Task<List<AppFile>> GetNAsync(int n)
    {
      List<AppFile> files = new();
      await foreach (BlobItem blobItem in blobContainerClient.GetBlobsAsync())
      {
        files.Add(new AppFile() { Id = blobItem.Name, Content = blobItem.Properties.ContentHash });
      }
      return files;
    }

    public async Task<List<AppFile>> GetAllAsync()
    {
      List<AppFile> files = new();
      await foreach (BlobItem blobItem in blobContainerClient.GetBlobsAsync())
      {
        files.Add(new AppFile() { Id = blobItem.Name, Content = blobItem.Properties.ContentHash });
      }
      return files;
    }

    public async Task<List<AppFile>> GetAllAsync(string partitionKey)
    {
      List<AppFile> files = new();
      await foreach (BlobItem blobItem in blobContainerClient.GetBlobsAsync())
      {
        files.Add(new AppFile() { Id = blobItem.Name, Content = blobItem.Properties.ContentHash });
      }
      return files;
    }

    public async Task<AppFile> GetByIdAsync(string rowKey, string partitionKey)
    {
      BlobClient blobClient = blobContainerClient.GetBlobClient(rowKey);
      using var memoryStream = new MemoryStream();
      await blobClient.DownloadToAsync(memoryStream);
      return new AppFile() { Id = rowKey, Content = memoryStream.ToArray() };
    }

    public Task<AppFile> GetDefault()
    {
      return null;
    }

    public async Task CreateAsync(AppFile file)
    {
      BlobClient blobClient = blobContainerClient.GetBlobClient(file.Id);
      await blobClient.UploadAsync(new BinaryData(file.Content));
      AppFileEntity fileEntity = new(file.Id, blobClient.Uri.ToString());
      await client.AddEntityAsync(fileEntity);
    }

    public async Task UpdateAsync(AppFile file)
    {
      BlobClient blobClient = blobContainerClient.GetBlobClient(file.Id);
      await blobClient.UploadAsync(new BinaryData(file.Content), overwrite: blobClient.Exists());
      AppFileEntity fileEntity = new(file.Id, blobClient.Uri.ToString());
      await client.UpsertEntityAsync(fileEntity, TableUpdateMode.Merge);
    }

    public async Task DeleteAsync(string rowKey, string partitionKey)
    {
      BlobClient blobClient = blobContainerClient.GetBlobClient(rowKey);
      await blobClient.DeleteAsync();
      await client.DeleteEntityAsync(partitionKey, rowKey);
    }

    public Task CreateTFVarsAsync(AppFile file)
    {
      throw new NotImplementedException();
    }
  }
}
