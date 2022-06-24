using AutomationForm.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace AutomationForm.Controllers
{
    public class RestHelper : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly string collectionUri;
        private readonly string project;
        private readonly string repositoryId;
        private readonly string PAT;
        private readonly string branch;
        private HttpClient client;
        public RestHelper(IConfiguration configuration)
        {
            collectionUri   = configuration["CollectionUri"];
            project         = configuration["Project"];
            repositoryId    = configuration["RepositoryId"];
            PAT             = configuration["PAT"];
            branch          = configuration["SourceBranch"];

            client = new HttpClient();
            
            client.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic",
                Convert.ToBase64String(
                    System.Text.ASCIIEncoding.ASCII.GetBytes(
                        string.Format("{0}:{1}", "", PAT))));

            client.DefaultRequestHeaders.Add("User-Agent", "sap-automation");
        }
        public async Task UpdateRepo(string path, string content)
        {
            string getUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/refs/?filter=heads/{branch}";
            string postUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/pushes?api-version=5.1";
            string ooId;

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            response.EnsureSuccessStatusCode();

            string responseBody = await response.Content.ReadAsStringAsync();
            ooId = JsonDocument.Parse(responseBody).RootElement.GetProperty("value")[0].GetProperty("objectId").GetString();

            // CREATE REQUEST BODY AND UPDATE
            Refupdate refUpdate = new Refupdate()
            {
                name = $"refs/heads/{branch}",
                oldObjectId = ooId
            };
            GitRequestBody requestBody = new GitRequestBody()
            {
                refUpdates = new Refupdate[] { refUpdate },
            };
            StringContent editContent = Helper.CreateHttpContent("edit", path, content, requestBody);

            // try to edit file (if it exists)
            HttpResponseMessage editResponse = await client.PostAsync(postUri, editContent);

            // add file on unsuccessful edit (because it does not exist)
            if (!editResponse.IsSuccessStatusCode)
            {
                StringContent addContent = Helper.CreateHttpContent("add", path, content, requestBody);
                HttpResponseMessage addResponse = await client.PostAsync(postUri, addContent);
                addResponse.EnsureSuccessStatusCode();
            }
        }
        public async Task TriggerPipeline(string pipelineId, string id, bool system, string workload_environment, string environment)
        {
            string postUri = $"{collectionUri}{project}/_apis/pipelines/{pipelineId}/runs?api-version=6.0-preview.1";

            PipelineRequestBody requestBody = new PipelineRequestBody
            {
                resources = new Resources
                {
                    repositories = new Repositories
                    {
                        self = new Self
                        {
                            refName = $"refs/heads/{branch}"
                        }
                    }
                }
            };
            if (system)
            {
                requestBody.templateParameters = new Templateparameters
                {
                    sap_system = id,
                    environment = workload_environment
                };
            }
            else
            {
                requestBody.templateParameters = new Templateparameters
                {
                    workload_zone = id,
                    deployer_environment_parameter = environment,
                    workload_environment_parameter = workload_environment
                };
            }

            string requestJson = JsonSerializer.Serialize(requestBody, typeof(PipelineRequestBody), new JsonSerializerOptions() { IgnoreNullValues = true });
            StringContent content = new StringContent(requestJson, Encoding.ASCII, "application/json");

            // TRIGGER PIPELINE

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            response.EnsureSuccessStatusCode();
        }
        public async Task<string[]> GetTemplateFileNames(string scopePath)
        {
            string getUri = $"https://api.github.com/repos/Azure/sap-automation/contents/{scopePath}?ref=main";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            response.EnsureSuccessStatusCode();
            
            string responseBody = await response.Content.ReadAsStringAsync();
            List<string> fileNames = new List<string>();

            JsonElement values = JsonDocument.Parse(responseBody).RootElement;
            foreach (var value in values.EnumerateArray())
            {
                string path = value.GetProperty("path").GetString() + "/";
                string filename = value.GetProperty("name").GetString() + ".tfvars";
                fileNames.Add(path + filename);
            }

            return fileNames.ToArray();
        }
        public async Task<string> GetTemplateFile(string path)
        {
            string getUri = $"https://api.github.com/repos/Azure/sap-automation/contents/{path}?ref=main";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            response.EnsureSuccessStatusCode();

            string responseBody = await response.Content.ReadAsStringAsync();

            string bitstring = JsonDocument.Parse(responseBody).RootElement.GetProperty("content").GetString();
            return Encoding.UTF8.GetString(Convert.FromBase64String(bitstring));
        }

    }
}
