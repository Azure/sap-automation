using AutomationForm.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Newtonsoft;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using JsonSerializer = System.Text.Json.JsonSerializer;
using System.Threading.Tasks;

namespace AutomationForm.Controllers
{
    public class RestHelper : Controller
    {
        private readonly string collectionUri;
        private readonly string project;
        private readonly string repositoryId;
        private readonly string PAT;
        private readonly string branch;
        private HttpClient client;
        public RestHelper(IConfiguration configuration)
        {
            collectionUri   = configuration["CollectionUri"];
            project         = configuration["ProjectName"];
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

        // Get ADO project id
        public async Task<string> GetProjectId()
        {
            string getUri = $"{collectionUri}_apis/projects/{project}?api-version=7.1-preview.4";
            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            return JsonDocument.Parse(responseBody).RootElement.GetProperty("id").GetString();
        }

        // Add or edit a file in ADO
        public async Task UpdateRepo(string path, string content)
        {
            string getUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/refs/?filter=heads/{branch}";
            string postUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/pushes?api-version=5.1";
            string ooId;

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            ooId = JsonDocument.Parse(responseBody).RootElement.GetProperty("value")[0].GetProperty("objectId").GetString();

            // Create request body
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
                string addResponseBody = await addResponse.Content.ReadAsStringAsync();
                HandleResponse(addResponse, addResponseBody);
            }
        }

        // Trigger a pipeline in azure devops
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

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);
        }

        // Get an array of file names from azure sap-automation region given a directory
        public async Task<string[]> GetTemplateFileNames(string scopePath)
        {
            string getUri = $"https://api.github.com/repos/Azure/sap-automation/contents/{scopePath}?ref=main";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);
            
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

        // Get a file from azure sap-automation repository
        public async Task<string> GetTemplateFile(string path)
        {
            string getUri = $"https://api.github.com/repos/Azure/sap-automation/contents/{path}?ref=main";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            string bitstring = JsonDocument.Parse(responseBody).RootElement.GetProperty("content").GetString();
            return Encoding.UTF8.GetString(Convert.FromBase64String(bitstring));
        }

        // List all variable groups from azure devops
        public async Task<EnvironmentModel[]> GetVariableGroups()
        {
            string getUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups?api-version=6.0-preview.2";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            JsonElement values = JsonDocument.Parse(responseBody).RootElement.GetProperty("value");
            
            List<EnvironmentModel> variableGroups = new List<EnvironmentModel>();

            foreach (var value in values.EnumerateArray())
            {
                EnvironmentModel environment = JsonSerializer.Deserialize<EnvironmentModel>(value.ToString());
                if (environment.name.StartsWith("SDAF-"))
                {
                    environment.name = environment.name.Replace("SDAF-", "");
                    variableGroups.Add(environment);
                }
                
            }

            return variableGroups.ToArray();
        }
        
        // Get a list of all variable group names for use in a dropdown
        public async Task<List<SelectListItem>> GetEnvironmentsList()
        {
            string getUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups?api-version=6.0-preview.2";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            JsonElement values = JsonDocument.Parse(responseBody).RootElement.GetProperty("value");
            
            List<SelectListItem> variableGroups = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };

            foreach (var value in values.EnumerateArray())
            {
                string text = value.GetProperty("name").ToString().Replace("SDAF-", "");
                variableGroups.Add(new SelectListItem
                {
                    Text = text,
                    Value = text
                });
            }

            return variableGroups;
        }

        // Get a specific variable group from azure devops
        public async Task<EnvironmentModel> GetVariableGroup(int id)
        {
            string getUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups/{id}?api-version=6.0-preview.2";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            EnvironmentModel environment = JsonSerializer.Deserialize<EnvironmentModel>(responseBody);
            environment.name = environment.name.Replace("SDAF-", "");
            return environment;
        }

        // Create a variable group in azure devops
        public async Task CreateVariableGroup(EnvironmentModel environment, string newName, string description)
        {
            string postUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups?api-version=6.0-preview.2";

            string projectId = GetProjectId().Result;

            newName = "SDAF-" + newName.Replace("SDAF-", "");
            environment.name = newName;
            environment.variableGroupProjectReferences = new VariableGroupProjectReference[]
                {
                    new VariableGroupProjectReference
                    {
                        name = newName,
                        description = description,
                        projectReference = new ProjectReference
                        {
                            id = projectId,
                            name = project
                        }
                    }
                };

            string requestJson = JsonSerializer.Serialize(environment, typeof(EnvironmentModel), new JsonSerializerOptions() { IgnoreNullValues = true });
            StringContent content = new StringContent(requestJson, Encoding.ASCII, "application/json");
            
            HttpResponseMessage response = await client.PostAsync(postUri, content);
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

        }

        // Update a variable group in azure devops
        public async Task UpdateVariableGroup(EnvironmentModel environment, string newName, string description)
        {
            string uri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups/{environment.id}?api-version=6.0-preview.2";

            // Get the existing environment
            using HttpResponseMessage getResponse = client.GetAsync(uri).Result;
            string getResponseBody = await getResponse.Content.ReadAsStringAsync();
            HandleResponse(getResponse, getResponseBody);

            EnvironmentModel existingEnvironment = JsonSerializer.Deserialize<EnvironmentModel>(getResponseBody);

            // Persist and update the project reference
            environment.variableGroupProjectReferences = existingEnvironment.variableGroupProjectReferences;
            if (environment.variableGroupProjectReferences != null && environment.variableGroupProjectReferences.Length > 0)
            {
                newName = "SDAF-" + newName.Replace("SDAF-", "");
                environment.variableGroupProjectReferences[0].name = newName;
                environment.variableGroupProjectReferences[0].description = description;
            }
            else
            {
                throw new Exception("Existing environment project reference was empty");
            }

            // Persist any existing variables
            string environmentJsonString    = JsonConvert.SerializeObject(environment);
            string variablesJsonString      = JsonDocument.Parse(getResponseBody).RootElement.GetProperty("variables").ToString();
            dynamic dynamicEnvironment      = JsonConvert.DeserializeObject(environmentJsonString);
            dynamic dynamicVariables        = JsonConvert.DeserializeObject(variablesJsonString);

            dynamicVariables.SPN_secret         = JToken.FromObject(environment.variables.SPN_secret);
            dynamicVariables.SPN_tenant         = JToken.FromObject(environment.variables.SPN_tenant);
            dynamicVariables.SPN_subscriptionID = JToken.FromObject(environment.variables.SPN_subscriptionID);
            dynamicVariables.SPN_App_ID         = JToken.FromObject(environment.variables.SPN_App_ID);

            dynamicEnvironment.variables = dynamicVariables;

            // Make the put call
            string requestJson = JsonConvert.SerializeObject(dynamicEnvironment, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
            StringContent content = new StringContent(requestJson, Encoding.ASCII, "application/json");

            HttpResponseMessage putResponse = await client.PutAsync(uri, content);
            string putResponseBody = await putResponse.Content.ReadAsStringAsync();
            HandleResponse(putResponse, putResponseBody);
        }

        private void HandleResponse(HttpResponseMessage response, string responseBody)
        {
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(JsonDocument.Parse(responseBody).RootElement.GetProperty("message").ToString());
            }
        }

    }
}
