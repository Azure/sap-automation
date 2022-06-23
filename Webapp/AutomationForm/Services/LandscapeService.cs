using MongoDB.Driver;
using System.Threading.Tasks;
using System.Collections.Generic;
using AutomationForm.Models;

namespace AutomationForm.Services
{
    public class LandscapeService : ILandscapeService<LandscapeModel>
    {
        private readonly IMongoCollection<LandscapeModel> _landscapes;

        public LandscapeService(MongoService mongo, IDatabaseSettings settings)
        {
            var db = mongo.GetClient().GetDatabase(settings.DatabaseName);
            _landscapes = db.GetCollection<LandscapeModel>(settings.LandscapeCollectionName);
        }

        public Task<List<LandscapeModel>> GetNAsync(int n)
        {
            return _landscapes.Find(landscape => true).Limit(n).ToListAsync();
        }
        
        public Task<List<LandscapeModel>> GetAllAsync()
        {
            return _landscapes.Find(landscape => true).ToListAsync();
        }

        public Task<LandscapeModel> GetByIdAsync(string id)
        {
            return _landscapes.Find(p => p.Id == id).FirstOrDefaultAsync();
        }

        public Task CreateAsync(LandscapeModel landscape)
        {
            return _landscapes.InsertOneAsync(landscape);
        }

        public Task<LandscapeModel> UpdateAsync(LandscapeModel update)
        {
            return _landscapes.FindOneAndReplaceAsync(
                Builders<LandscapeModel>.Filter.Eq(p => p.Id, update.Id),
                update,
                new FindOneAndReplaceOptions<LandscapeModel> { ReturnDocument = ReturnDocument.After });
        }

        public Task DeleteAsync(string id)
        {
            return _landscapes.DeleteOneAsync(p => p.Id == id);
        }
    }
}