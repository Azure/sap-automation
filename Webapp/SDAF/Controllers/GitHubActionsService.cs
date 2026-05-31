using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

public class GitHubActionsService
{
    private readonly HttpClient _httpClient;
    private readonly string _token;
    private readonly string _owner;
    private readonly string _repo;

    public GitHubActionsService(string token, string owner, string repo)
    {
        _token = token;
        _owner = owner;
        _repo = repo;
        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("MyApp", "1.0"));
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
    }

    public async Task<bool> TriggerWorkflowAsync(string workflowFileName, string branch, object inputs = null)
    {
        var url = $"https://api.github.com/repos/{_owner}/{_repo}/actions/workflows/{workflowFileName}/dispatches";
        
        var requestBody = new
        {
            @ref = branch,
            inputs = inputs ?? new { }
        };

        var json = JsonConvert.SerializeObject(requestBody);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync(url, content);
        return response.IsSuccessStatusCode; // Returns 204 No Content on success
    }

    public async Task<string> GetWorkflowRunsAsync(string workflowFileName)
    {
        var url = $"https://api.github.com/repos/{_owner}/{_repo}/actions/workflows/{workflowFileName}/runs";
        var response = await _httpClient.GetAsync(url);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync();
    }
}