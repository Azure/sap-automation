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
    public class LandscapeService : ITableStorageService<LandscapeEntity>
    {
        private readonly Lazy<Task<TableClient>> client;
        private readonly Lazy<Task<BlobContainerClient>> tfvarsBlobContainerClient;

        public LandscapeService(TableStorageService tableStorageService, IDatabaseSettings settings)
        {
            client = new(() => tableStorageService.GetTableClient(settings.LandscapeCollectionName));
            tfvarsBlobContainerClient = new(() => tableStorageService.GetBlobClient(settings.TfVarBlobCollectionName));
        }

        public async Task<List<LandscapeEntity>> GetNAsync(int n)
        {
            TableClient tableClient = await client.Value;
            return await tableClient.QueryAsync<LandscapeEntity>(entity => true, n).ToListAsync();
        }

        public async Task<List<LandscapeEntity>> GetAllAsync()
        {
            TableClient tableClient = await client.Value;
            return await tableClient.QueryAsync<LandscapeEntity>(entity => true).ToListAsync();
        }

        public async Task<List<LandscapeEntity>> GetAllAsync(string partitionKey)
        {
            TableClient tableClient = await client.Value;
            return await tableClient.QueryAsync<LandscapeEntity>(entity => entity.PartitionKey == partitionKey).ToListAsync();
        }

        public async Task<LandscapeEntity> GetByIdAsync(string rowKey, string partitionKey)
        {
            TableClient tableClient = await client.Value;
            try
            {
                return await tableClient.GetEntityAsync<LandscapeEntity>(partitionKey, rowKey);
            }
            catch (RequestFailedException ex) when (ex.Status == 404)
            {
                // Entities created before the PartitionKey convention changed from
                // "environment" to the full Id (see LandscapeEntity) will not be found
                // by the (partitionKey, rowKey) pair above. Fall back to a RowKey-only
                // lookup so pre-existing Table Storage rows remain reachable.
                AsyncPageable<LandscapeEntity> matches = tableClient.QueryAsync<LandscapeEntity>(entity => entity.RowKey == rowKey);
                return await matches.FirstOrDefaultAsync();
            }
        }

        public async Task<LandscapeEntity> GetDefault()
        {
            TableClient tableClient = await client.Value;
            AsyncPageable<LandscapeEntity> defaults = tableClient.QueryAsync<LandscapeEntity>(entity => entity.IsDefault);
            return await defaults.FirstOrDefaultAsync();
        }

        public async Task CreateAsync(LandscapeEntity entity)
        {
            TableClient tableClient = await client.Value;
            await tableClient.AddEntityAsync(entity);
        }

        public async Task UpdateAsync(LandscapeEntity entity)
        {
            TableClient tableClient = await client.Value;
            await tableClient.UpsertEntityAsync(entity, TableUpdateMode.Merge);
        }

        public async Task DeleteAsync(string rowKey, string partitionKey)
        {
            TableClient tableClient = await client.Value;
            await tableClient.DeleteEntityAsync(partitionKey, rowKey);
        }

        public async Task CreateTFVarsAsync(AppFile file)
        {
            BlobContainerClient containerClient = await tfvarsBlobContainerClient.Value;
            BlobClient blobClient = containerClient.GetBlobClient(file.Id);
            await blobClient.UploadAsync(new BinaryData(file.Content), overwrite: true);
        }
    }
}
