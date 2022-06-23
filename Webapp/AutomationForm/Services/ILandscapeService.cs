using System.Threading.Tasks;
using System.Collections.Generic;
using AutomationForm.Models;

namespace AutomationForm.Services
{
    public interface ILandscapeService<T>
    {
        public Task<List<T>> GetNAsync(int n);
        public Task<List<T>> GetAllAsync();
        public Task<T> GetByIdAsync(string id);
        public Task CreateAsync(T model);
        public Task<T> UpdateAsync(T model);
        public Task DeleteAsync(string id);
    }
}