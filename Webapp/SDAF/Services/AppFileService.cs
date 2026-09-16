// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    public class AppFileService : ITableStorageService<AppFile>
    {
        private readonly Lazy<Task<TableClient>> client;
        private readonly Lazy<Task<BlobContainerClient>> blobContainerClient;

        public AppFileService(TableStorageService tableStorageService, IDatabaseSettings settings)
        {
            client = new(() => tableStorageService.GetTableClient(settings.AppFileCollectionName));
            blobContainerClient = new(() => tableStorageService.GetBlobClient(settings.AppFileBlobCollectionName));
        }

        public async Task<List<AppFile>> GetNAsync(int n)
        {
            List<AppFile> files = [];
            BlobContainerClient containerClient = await blobContainerClient.Value;
            await foreach (BlobItem blobItem in containerClient.GetBlobsAsync())
            {
                files.Add(new AppFile() { Id = blobItem.Name, Content = blobItem.Properties.ContentHash });
            }
            return files;
        }

        public async Task<List<AppFile>> GetAllAsync()
        {
            List<AppFile> files = [];
            BlobContainerClient containerClient = await blobContainerClient.Value;
            await foreach (BlobItem blobItem in containerClient.GetBlobsAsync())
            {
                files.Add(new AppFile() { Id = blobItem.Name, Content = blobItem.Properties.ContentHash });
            }
            return files;
        }

        public async Task<List<AppFile>> GetAllAsync(string partitionKey)
        {
            List<AppFile> files = [];
            BlobContainerClient containerClient = await blobContainerClient.Value;
            await foreach (BlobItem blobItem in containerClient.GetBlobsAsync())
            {
                files.Add(new AppFile() { Id = blobItem.Name, Content = blobItem.Properties.ContentHash });
            }
            return files;
        }

        public async Task<AppFile> GetByIdAsync(string rowKey, string partitionKey)
        {
            BlobContainerClient containerClient = await blobContainerClient.Value;
            BlobClient blobClient = containerClient.GetBlobClient(rowKey);
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
            BlobContainerClient containerClient = await blobContainerClient.Value;
            TableClient tableClient = await client.Value;
            BlobClient blobClient = containerClient.GetBlobClient(file.Id);
            await blobClient.UploadAsync(new BinaryData(file.Content));
            AppFileEntity fileEntity = new(file.Id, blobClient.Uri.ToString());
            await tableClient.AddEntityAsync(fileEntity);
        }

        public async Task UpdateAsync(AppFile file)
        {
            BlobContainerClient containerClient = await blobContainerClient.Value;
            TableClient tableClient = await client.Value;
            BlobClient blobClient = containerClient.GetBlobClient(file.Id);
            await blobClient.UploadAsync(new BinaryData(file.Content), overwrite: true);
            AppFileEntity fileEntity = new(file.Id, blobClient.Uri.ToString());
            await tableClient.UpsertEntityAsync(fileEntity, TableUpdateMode.Merge);
        }

        public async Task DeleteAsync(string rowKey, string partitionKey)
        {
            BlobContainerClient containerClient = await blobContainerClient.Value;
            TableClient tableClient = await client.Value;
            BlobClient blobClient = containerClient.GetBlobClient(rowKey);
            await blobClient.DeleteAsync();
            await tableClient.DeleteEntityAsync(partitionKey, rowKey);
        }

        public Task CreateTFVarsAsync(AppFile file)
        {
            throw new NotImplementedException();
        }
    }
}
