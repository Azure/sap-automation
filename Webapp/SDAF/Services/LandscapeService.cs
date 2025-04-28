// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using Azure;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    public class LandscapeService(TableStorageService tableStorageService, IDatabaseSettings settings) : ITableStorageService<LandscapeEntity>
    {
        private readonly TableClient client = tableStorageService.GetTableClient(settings.LandscapeCollectionName).Result;
        private readonly BlobContainerClient tfvarsBlobContainerClient = tableStorageService.GetBlobClient(settings.TfVarBlobCollectionName).Result;

        public async Task<List<LandscapeEntity>> GetNAsync(int n)
        {
            return await client.QueryAsync<LandscapeEntity>(entity => true, n).ToListAsync();
        }

        public async Task<List<LandscapeEntity>> GetAllAsync()
        {
            return await client.QueryAsync<LandscapeEntity>(entity => true).ToListAsync();
        }

        public async Task<List<LandscapeEntity>> GetAllAsync(string partitionKey)
        {
            return await client.QueryAsync<LandscapeEntity>(entity => entity.PartitionKey == partitionKey).ToListAsync();
        }

        public async Task<LandscapeEntity> GetByIdAsync(string rowKey, string partitionKey)
        {
            return await client.GetEntityAsync<LandscapeEntity>(partitionKey, rowKey);
        }

        public async Task<LandscapeEntity> GetDefault()
        {
            AsyncPageable<LandscapeEntity> defaults = client.QueryAsync<LandscapeEntity>(entity => entity.IsDefault);
            return await defaults.FirstOrDefaultAsync();
        }

        public Task CreateAsync(LandscapeEntity entity)
        {
            return client.AddEntityAsync(entity);
        }

        public Task UpdateAsync(LandscapeEntity entity)
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
