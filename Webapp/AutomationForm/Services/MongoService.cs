using MongoDB.Driver;
using AutomationForm.Models;
using System.Web;
using Microsoft.IdentityModel.Protocols;
using Microsoft.Extensions.Configuration;

namespace AutomationForm.Services
{
    public class MongoService
    {
        private static MongoClient _client;
        private readonly IConfiguration _configuration;

        public MongoService(IDatabaseSettings settings, IConfiguration configuration)
        {
            _configuration = configuration;
            _client = new MongoClient(_configuration.GetConnectionString(settings.MongoConnectionStringKey));
        }

        public MongoClient GetClient()
        {
            return _client;
        }
    }
}