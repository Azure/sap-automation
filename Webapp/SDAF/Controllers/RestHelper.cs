// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Azure.Core;
using Azure.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.VisualStudio.Services.Client;
using Microsoft.VisualStudio.Services.Common;
using Microsoft.VisualStudio.Services.TenantPolicy;
using Microsoft.VisualStudio.Services.WebApi;

using JsonSerializer = System.Text.Json.JsonSerializer;

#pragma warning disable SYSLIB0020
namespace SDAFWebApp.Controllers
{
    public class RestHelper : Controller
    {
        private readonly string collectionUri;
        private readonly string project;
        private readonly string repositoryId;
        private readonly string PAT;
        private readonly string branch;
        private readonly string sdafGeneralId;
        private readonly string sdafControlPlaneEnvironment;
        private readonly string sdafControlPlaneLocation;
        private readonly string tenantId;
        private readonly string managedIdentityClientId;

        private readonly Azure.Identity.DefaultAzureCredential credential;

        private readonly string sampleUrl = "https://api.github.com/repos/Azure/SAP-automation-samples";

        private HttpClient client;

        private JsonSerializerOptions jsonSerializerOptions;

        public RestHelper(IConfiguration configuration, string type = "ADO")
        {
            collectionUri = configuration["CollectionUri"];
            project = configuration["ProjectName"];
            repositoryId = configuration["RepositoryId"];
            PAT = configuration["PAT"];
            string devops_authentication = configuration["AUTHENTICATION_TYPE"];
            branch = configuration["SourceBranch"];
            sdafGeneralId = configuration["SDAF_GENERAL_GROUP_ID"];
            sdafControlPlaneEnvironment = configuration["CONTROLPLANE_ENV"];
            sdafControlPlaneLocation = configuration["CONTROLPLANE_LOC"];
            tenantId = configuration["AZURE_TENANT_ID"];
            managedIdentityClientId = configuration["OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"];

            jsonSerializerOptions = new JsonSerializerOptions() { IgnoreNullValues = true };

            if (type == "ADO")
            {
                if (devops_authentication == "PAT")
                {
                    client = new HttpClient();
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic",
                    Convert.ToBase64String(
                        System.Text.ASCIIEncoding.ASCII.GetBytes(
                            string.Format("{0}:{1}", "", PAT))));
                }
                else
                {
                    if (string.IsNullOrEmpty(tenantId) || string.IsNullOrEmpty(managedIdentityClientId))
                    {
                        throw new ArgumentNullException("TenantId and ManagedIdentityClientId must be provided for Managed Identity authentication.");
                    }

                    credential = new DefaultAzureCredential(
                        new DefaultAzureCredentialOptions
                        {
                            TenantId = tenantId,
                            ManagedIdentityClientId = managedIdentityClientId
                        });

                    //var tokenRequestContext = new TokenRequestContext(new[] { "https://management.azure.com/.default", "499b84ac-1321-427f-aa17-267ca6975798/.default" });

                    var tokenRequestContext = new TokenRequestContext(VssAadSettings.DefaultScopes);
                    var token = credential.GetToken(tokenRequestContext, CancellationToken.None);

                    var accessToken = token.Token;

                    client = new HttpClient();
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer",
                        accessToken);
                }

                client.DefaultRequestHeaders.Accept.Add(
                    new MediaTypeWithQualityHeaderValue("application/json"));
                client.DefaultRequestHeaders.Add("User-Agent", "sap-automation");
            }
            else
            {
                client = new HttpClient();

                client.DefaultRequestHeaders.Accept.Add(
                    new MediaTypeWithQualityHeaderValue("application/json"));

                client.DefaultRequestHeaders.Add("User-Agent", "sap-automation");
            }
        }

        // Get ADO project id
        public async Task<string> GetProjectId()
        {
            string getUri = $"{collectionUri}_apis/projects/{project}?api-version=7.1";
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

            // Dynamically retrieve path
            string pathBase = await GetVariableFromVariableGroup(sdafGeneralId, "SDAF-General", "Deployment_Configuration_Path");
            path = pathBase + path;

            // Create request body
            Refupdate refUpdate = new()
            {
                name = $"refs/heads/{branch}",
                oldObjectId = ooId
            };
            GitRequestBody requestBody = new()
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
        public async Task TriggerPipeline(string pipelineId, PipelineRequestBody requestBody)
        {
            string getUri = $"{collectionUri}{project}/_apis/pipelines/{pipelineId}";
            using HttpResponseMessage getResponse = client.GetAsync(getUri).Result;
            string getResponseBody = await getResponse.Content.ReadAsStringAsync();
            HandleResponse(getResponse, getResponseBody);

            string postUri = $"{collectionUri}{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1";

            string requestJson = JsonSerializer.Serialize(requestBody, typeof(PipelineRequestBody), jsonSerializerOptions);
            StringContent content = new(requestJson, Encoding.UTF8, "application/json");

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);
        }

        // Get an array of file names from azure sap-automation region given a directory
        public async Task<string[]> GetTemplateFileNames(string scopePath)
        {
            string getUri = $"{sampleUrl}/contents/{scopePath}?ref=main";
            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            List<string> fileNames = [];

            JsonElement values = JsonDocument.Parse(responseBody).RootElement;
            foreach (var value in values.EnumerateArray())
            {
                string type = value.GetProperty("type").GetString();
                string path = value.GetProperty("path").GetString();
                if (type == "dir")
                {
                    string[] subFiles = await GetTemplateFileNames(path);
                    foreach (string subFile in subFiles)
                    {
                        fileNames.Add(subFile);
                    }
                }
                else if (type == "file")
                {
                    if (path.EndsWith(".tfvars"))
                    {
                        fileNames.Add(path);
                    }
                }
            }

            return fileNames.ToArray();
        }

        // Get a file from azure sap-automation repository
        public async Task<string> GetTemplateFile(string path)
        {
            string getUri = $"{sampleUrl}/contents/{path}?ref=main";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            string bitstring = JsonDocument.Parse(responseBody).RootElement.GetProperty("content").GetString();
            return Encoding.UTF8.GetString(Convert.FromBase64String(bitstring));
        }

        // Get the json response for all variable groups in an ado project
        public async Task<JsonElement> GetVariableGroupsJson()
        {
            string getUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups?api-version=7.1";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            JsonElement values = JsonDocument.Parse(responseBody).RootElement.GetProperty("value");
            return values;
        }

        // List all variable groups from azure devops
        public async Task<EnvironmentModel[]> GetVariableGroups()
        {
            JsonElement values = await GetVariableGroupsJson();

            List<EnvironmentModel> variableGroups = [];

            foreach (var value in values.EnumerateArray())
            {
                EnvironmentModel environment = JsonSerializer.Deserialize<EnvironmentModel>(value.ToString());

                environment.sdafControlPlaneEnvironment = sdafControlPlaneEnvironment;
                if (!environment.name.EndsWith("-" + sdafControlPlaneEnvironment))
                {
                    if (environment.name.StartsWith("SDAF-"))
                    {
                        environment.name = environment.name.Replace("SDAF-", "");
                        variableGroups.Add(environment);
                    }
                }

            }

            return variableGroups.ToArray();
        }

        // Get a list of all variable group names for use in a dropdown
        public async Task<List<SelectListItem>> GetEnvironmentsList()
        {
            JsonElement values = await GetVariableGroupsJson();

            List<SelectListItem> variableGroups =
      [
                new SelectListItem { Text = "", Value = "" }
            ];

            foreach (var value in values.EnumerateArray())
            {
                string groupName = value.GetProperty("name").ToString();
                if (groupName.StartsWith("SDAF-"))
                {
                    string text = value.GetProperty("name").ToString().Replace("SDAF-", "");
                    variableGroups.Add(new SelectListItem
                    {
                        Text = text,
                        Value = text
                    });

                }
            }

            return variableGroups;
        }

        // Get a specific variable group from azure devops
        public async Task<EnvironmentModel> GetVariableGroup(int id)
        {
            string getUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups/{id}?api-version=7.1";

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            EnvironmentModel environment = JsonSerializer.Deserialize<EnvironmentModel>(responseBody);
            environment.name = environment.name.Replace("SDAF-", "");
            return environment;
        }

        // Get a variable group id by name in ado
        public async Task<string> GetVariableGroupIdFromName(string name)
        {
            JsonElement values = await GetVariableGroupsJson();

            foreach (var value in values.EnumerateArray())
            {
                if (value.GetProperty("name").ToString() == name)
                {
                    return value.GetProperty("id").ToString();
                }
            }
            return null;
        }

        // Get a specific variables value from a variable group in ado
        public async Task<string> GetVariableFromVariableGroup(string id, string variableGroupName, string variableName)
        {
            try
            {
                if (id == null || id == "")
                {
                    id = await GetVariableGroupIdFromName(variableGroupName);
                    if (id == null)
                    {
                        throw new Exception();
                    }
                }
                string getUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups/{id}?api-version=7.1";

                using HttpResponseMessage response = client.GetAsync(getUri).Result;
                string responseBody = await response.Content.ReadAsStringAsync();
                HandleResponse(response, responseBody);

                JsonElement variables = JsonDocument.Parse(responseBody).RootElement.GetProperty("variables");
                string value = variables.GetProperty(variableName).GetProperty("value").GetString();
                if (value.EndsWith('/'))
                {
                    value = value.Remove(value.Length - 1);
                }
                return value;
            }
            catch
            {
                return "WORKSPACES";
            }
        }

        // Create a variable group in azure devops
        public async Task CreateVariableGroup(EnvironmentModel environment, string newName, string description)
        {
            string postUri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups?api-version=7.1";

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

            string requestJson = JsonSerializer.Serialize(environment, typeof(EnvironmentModel), jsonSerializerOptions);
            StringContent content = new(requestJson, Encoding.ASCII, "application/json");

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

        }

        // Update a variable group in azure devops
        public async Task UpdateVariableGroup(EnvironmentModel environment, string newName, string description)
        {
            string uri = $"{collectionUri}{project}/_apis/distributedtask/variablegroups/{environment.id}?api-version=7.1";

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
            string environmentJsonString = JsonConvert.SerializeObject(environment);
            string variablesJsonString = JsonDocument.Parse(getResponseBody).RootElement.GetProperty("variables").ToString();
            dynamic dynamicEnvironment = JsonConvert.DeserializeObject(environmentJsonString);
            dynamic dynamicVariables = JsonConvert.DeserializeObject(variablesJsonString);

            dynamicVariables.Agent = JToken.FromObject(environment.variables.Agent);
            dynamicVariables.ARM_CLIENT_ID = JToken.FromObject(environment.variables.ARM_CLIENT_ID);
            dynamicVariables.ARM_CLIENT_SECRET = JToken.FromObject(environment.variables.ARM_CLIENT_SECRET);
            dynamicVariables.ARM_TENANT_ID = JToken.FromObject(environment.variables.ARM_TENANT_ID);
            dynamicVariables.ARM_SUBSCRIPTION_ID = JToken.FromObject(environment.variables.ARM_SUBSCRIPTION_ID);
            dynamicVariables.APPLICATION_CONFIGURATION_NAME = JToken.FromObject(environment.variables.APPLICATION_CONFIGURATION_NAME);
            dynamicVariables.TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME = JToken.FromObject(environment.variables.TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME);
            dynamicVariables.DEPLOYER_KEYVAULT = JToken.FromObject(environment.variables.DEPLOYER_KEYVAULT);
            dynamicVariables.CONTROL_PLANE_NAME = JToken.FromObject(environment.variables.CONTROL_PLANE_NAME);
            dynamicVariables.POOL = JToken.FromObject(environment.variables.POOL);

            dynamicEnvironment.variables = dynamicVariables;

            // Make the put call
            string requestJson = JsonConvert.SerializeObject(dynamicEnvironment, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
            StringContent content = new(requestJson, Encoding.ASCII, "application/json");

            HttpResponseMessage putResponse = await client.PutAsync(uri, content);
            string putResponseBody = await putResponse.Content.ReadAsStringAsync();
            HandleResponse(putResponse, putResponseBody);
        }

        static private void HandleResponse(HttpResponseMessage response, string responseBody)
        {
            if (!response.IsSuccessStatusCode)
            {
                string errorMessage;
                switch (response.StatusCode)
                {
                    case System.Net.HttpStatusCode.Unauthorized:
                        errorMessage = "Unauthorized, please ensure that the MSI/Personal Access Token has sufficient permissions and that it has not expired.";
                        break;
                    case System.Net.HttpStatusCode.NotFound:
                        errorMessage = "Could not find the template.";
                        break;
                    default:
                        errorMessage = JsonDocument.Parse(responseBody).RootElement.GetProperty("message").ToString();
                        break;
                }
                throw new HttpRequestException(errorMessage);
            }
        }

        public static List<ProductInfoHeaderValue> AppUserAgent { get; } =
        [
            new ProductInfoHeaderValue("SDAF")
        ];

    }
}
#pragma warning restore SYSLIB0020
