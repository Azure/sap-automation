using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;

namespace SDAFWebApp.Controllers
{
    public class GitHubEnvironmentHelper
    {
        private readonly HttpClient _httpClient;
        private readonly string _token;
        private readonly string _owner;
        private readonly string _repo;

        public GitHubEnvironmentHelper(string token, string owner, string repo)
        {
            _token = token;
            _owner = owner;
            _repo = repo;
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("SDAF", "1.0"));
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
        }

        public async Task<List<GitHubEnvironment>> ListEnvironmentsAsync()
        {
            var url = $"https://api.github.com/repos/{_owner}/{_repo}/environments";

            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<GitHubEnvironmentsResponse>(content);

            return result?.Environments ?? [];
        }

        public async Task<GitHubEnvironment> GetEnvironmentAsync(string environmentName)
        {
            var url = $"https://api.github.com/repos/{_owner}/{_repo}/environments/{environmentName}";

            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();
            var environment = JsonSerializer.Deserialize<GitHubEnvironment>(content);

            return environment;
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
