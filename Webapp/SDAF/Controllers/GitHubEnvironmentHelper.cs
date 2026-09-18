using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using SDAFWebApp.Services;

namespace SDAFWebApp.Controllers
{
    public class GitHubEnvironmentHelper
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private HttpClient HttpClient => _httpClientFactory.CreateClient(DevOpsHttpClientNames.GitHub);

        public GitHubEnvironmentHelper(IHttpClientFactory httpClientFactory, IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        public async Task<List<GitHubEnvironment>> ListEnvironmentsAsync(CancellationToken cancellationToken = default)
        {
            var (owner, repo) = GetRepository();
            var url = $"repos/{owner}/{repo}/environments";

            using var response = await HttpClient.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var result = JsonSerializer.Deserialize<GitHubEnvironmentsResponse>(content);

            return result?.Environments ?? [];
        }

        public async Task<GitHubEnvironment> GetEnvironmentAsync(
            string environmentName,
            CancellationToken cancellationToken = default)
        {
            var (owner, repo) = GetRepository();
            var url = $"repos/{owner}/{repo}/environments/{Uri.EscapeDataString(environmentName)}";

            using var response = await HttpClient.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            var environment = JsonSerializer.Deserialize<GitHubEnvironment>(content);

            return environment;
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

    public class GitHubEnvironmentsResponse
    {
        [System.Text.Json.Serialization.JsonPropertyName("total_count")]
        public int TotalCount { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("environments")]
        public List<GitHubEnvironment> Environments { get; set; }
    }

    public class GitHubEnvironment
    {
        [System.Text.Json.Serialization.JsonPropertyName("id")]
        public long Id { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("node_id")]
        public string NodeId { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("name")]
        public string Name { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("url")]
        public string Url { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("html_url")]
        public string HtmlUrl { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("created_at")]
        public DateTime CreatedAt { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("updated_at")]
        public DateTime UpdatedAt { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("protection_rules")]
        public List<ProtectionRule> ProtectionRules { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("deployment_branch_policy")]
        public DeploymentBranchPolicy DeploymentBranchPolicy { get; set; }
        public string SdafControlPlaneEnvironment { get; internal set; }
        public string Description { get; internal set; }
    }

    public class ProtectionRule
    {
        [System.Text.Json.Serialization.JsonPropertyName("id")]
        public long Id { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("node_id")]
        public string NodeId { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("type")]
        public string Type { get; set; }
    }

    public class DeploymentBranchPolicy
    {
        [System.Text.Json.Serialization.JsonPropertyName("protected_branches")]
        public bool ProtectedBranches { get; set; }

        [System.Text.Json.Serialization.JsonPropertyName("custom_branch_policies")]
        public bool CustomBranchPolicies { get; set; }
    }
}
