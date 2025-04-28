// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

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
    public class TableStorageService(IConfiguration configuration, IDatabaseSettings settings)
    {
        private readonly IConfiguration _configuration = configuration;
        private readonly IDatabaseSettings _settings = settings;

        public async Task<TableClient> GetTableClient(string table)
        {
            string devops_authentication = Environment.GetEnvironmentVariable("AUTHENTICATION_TYPE");
            string accountName = _configuration.GetConnectionString(_settings.ConnectionStringKey).Replace("blob", "table").Replace(".privatelink", "");
            var creds = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                TenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID"),
                ManagedIdentityClientId = Environment.GetEnvironmentVariable("OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID")
            });
            if (devops_authentication == "PAT")
            {
                creds = new DefaultAzureCredential();
            }
            var serviceClient = new TableServiceClient(
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

            var creds = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                TenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID"),
                ManagedIdentityClientId = Environment.GetEnvironmentVariable("OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID")
            });
            if (devops_authentication == "PAT")
            {
                creds = new DefaultAzureCredential();
            }

            var serviceClient = new BlobServiceClient(
              new Uri(accountName),
              creds);

            var blobClient = serviceClient.GetBlobContainerClient(container);
            await blobClient.CreateIfNotExistsAsync();
            return blobClient;
        }
    }
}
