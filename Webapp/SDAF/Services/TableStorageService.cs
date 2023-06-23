using AutomationForm.Models;
using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
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
            var serviceClient = new TableServiceClient(_configuration.GetConnectionString(_settings.ConnectionStringKey));
            var tableClient = serviceClient.GetTableClient(table);
            await tableClient.CreateIfNotExistsAsync();
            return tableClient;
        }

        public async Task<BlobContainerClient> GetBlobClient(string container)
        {
            var serviceClient = new BlobServiceClient(_configuration.GetConnectionString(_settings.ConnectionStringKey));
            var blobClient = serviceClient.GetBlobContainerClient(container);
            await blobClient.CreateIfNotExistsAsync();
            return blobClient;
        }
    }
}
