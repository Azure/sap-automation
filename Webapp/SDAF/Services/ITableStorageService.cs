using SDAFWebApp.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
  public interface ITableStorageService<T>
  {
    public Task<List<T>> GetNAsync(int n);
    public Task<List<T>> GetAllAsync();
    public Task<List<T>> GetAllAsync(string partitionKey);
    public Task<T> GetByIdAsync(string rowKey, string partitionKey);
    public Task<T> GetDefault();
    public Task CreateAsync(T model);
    public Task UpdateAsync(T model);
    public Task DeleteAsync(string rowKey, string partitionKey);
    public Task CreateTFVarsAsync(AppFile file);
  }
}
