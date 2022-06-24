using MongoDB.Driver;
using System.Threading.Tasks;
using System.Collections.Generic;
using AutomationForm.Models;

namespace AutomationForm.Services
{
    public class SystemService : ILandscapeService<SystemModel>
    {
        private readonly IMongoCollection<SystemModel> _systems;

        public SystemService(MongoService mongo, IDatabaseSettings settings)
        {
            var db = mongo.GetClient().GetDatabase(settings.DatabaseName);
            _systems = db.GetCollection<SystemModel>(settings.SystemCollectionName);
        }

        public Task<List<SystemModel>> GetNAsync(int n)
        {
            return _systems.Find(system => true).Limit(n).ToListAsync();
        }
        
        public Task<List<SystemModel>> GetAllAsync()
        {
            return _systems.Find(system => true).ToListAsync();
        }

        public Task<SystemModel> GetByIdAsync(string id)
        {
            return _systems.Find(p => p.Id == id).FirstOrDefaultAsync();
        }

        public Task CreateAsync(SystemModel system)
        {
            return _systems.InsertOneAsync(system);
        }

        public Task<SystemModel> UpdateAsync(SystemModel update)
        {
            return _systems.FindOneAndReplaceAsync(
                Builders<SystemModel>.Filter.Eq(p => p.Id, update.Id),
                update,
                new FindOneAndReplaceOptions<SystemModel> { ReturnDocument = ReturnDocument.After });
        }

        public Task DeleteAsync(string id)
        {
            return _systems.DeleteOneAsync(p => p.Id == id);
        }
    }
}