using MongoDB.Driver;
using System.Threading.Tasks;
using System.Collections.Generic;
using AutomationForm.Models;

namespace AutomationForm.Services
{
    public class AppFileService : ILandscapeService<AppFile>
    {
        private readonly IMongoCollection<AppFile> _files;

        public AppFileService(MongoService mongo, IDatabaseSettings settings)
        {
            var db = mongo.GetClient().GetDatabase(settings.DatabaseName);
            _files = db.GetCollection<AppFile>(settings.AppFileCollectionName);
        }

        public Task<List<AppFile>> GetNAsync(int n)
        {
            return _files.Find(file => true).Limit(n).ToListAsync();
        }

        public Task<List<AppFile>> GetAllAsync()
        {
            return _files.Find(file => true).ToListAsync();
        }

        public Task<AppFile> GetByIdAsync(string id)
        {
            return _files.Find(p => p.Id == id).FirstOrDefaultAsync();
        }

        public Task CreateAsync(AppFile file)
        {
            return _files.InsertOneAsync(file);
        }

        public Task<AppFile> UpdateAsync(AppFile update)
        {
            return _files.FindOneAndReplaceAsync(
                Builders<AppFile>.Filter.Eq(p => p.Id, update.Id),
                update,
                new FindOneAndReplaceOptions<AppFile> { ReturnDocument = ReturnDocument.After });
        }

        public Task DeleteAsync(string id)
        {
            return _files.DeleteOneAsync(p => p.Id == id);
        }
    }
}