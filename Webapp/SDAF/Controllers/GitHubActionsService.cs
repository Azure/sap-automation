using System;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using SDAFWebApp.Services;

namespace SDAFWebApp.Controllers;

public class GitHubActionsService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private HttpClient HttpClient => _httpClientFactory.CreateClient(DevOpsHttpClientNames.GitHub);

    public GitHubActionsService(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    public async Task<bool> TriggerWorkflowAsync(
        string workflowFileName,
        string branch,
        object inputs = null,
        CancellationToken cancellationToken = default)
    {
        var (owner, repo) = GetRepository();
        var url = $"repos/{owner}/{repo}/actions/workflows/{Uri.EscapeDataString(workflowFileName)}/dispatches";

        var requestBody = new
        {
            @ref = branch,
            inputs = inputs ?? new { }
        };

        var json = JsonConvert.SerializeObject(requestBody);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");

        using var response = await HttpClient.PostAsync(url, content, cancellationToken);
        return response.IsSuccessStatusCode; // Returns 204 No Content on success
    }

    public async Task<string> GetWorkflowRunsAsync(
        string workflowFileName,
        CancellationToken cancellationToken = default)
    {
        var (owner, repo) = GetRepository();
        var url = $"repos/{owner}/{repo}/actions/workflows/{Uri.EscapeDataString(workflowFileName)}/runs";
        using var response = await HttpClient.GetAsync(url, cancellationToken);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync(cancellationToken);
    }

    private (string Owner, string Repository) GetRepository()
    {
        string repository = _configuration["GITHUB_REPOSITORY"];
        string[] parts = repository?.Split('/', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts?.Length != 2)
        {
            throw new InvalidOperationException("GITHUB_REPOSITORY must be provided as 'owner/repository'.");
        }

        return (parts[0], parts[1]);
    }
}
