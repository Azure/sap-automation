// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Azure.Core;
using Azure.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NuGet.Common;
using Octokit;
using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

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
        private readonly string ghToken;
        private readonly string ghOrganization;
        private readonly string ghRepository;
        private readonly string repoType;
        private readonly string managedIdentityClientId;

        private readonly Azure.Identity.DefaultAzureCredential credential;

        private readonly string sampleUrl = "https://api.github.com/repos/Azure/SAP-automation-samples";

        private HttpClient client;

        private JsonSerializerOptions jsonSerializerOptions;

        private static void LogDebug(string message)
        {
            System.Diagnostics.Debug.WriteLine($"[RestHelper] {message}");
        }

        public RestHelper(IConfiguration configuration, string type = "ADO")
        {
            string devops_authentication;
            string ghOrgAndRepository;

            try
            {
                collectionUri = configuration["CollectionUri"];
                project = configuration["ProjectName"];
                repoType = type;
                repositoryId = configuration["RepositoryId"];
                PAT = configuration["PAT"];
                devops_authentication = configuration["AUTHENTICATION_TYPE"];
                branch = configuration["SourceBranch"];
                sdafGeneralId = configuration["SDAF_GENERAL_GROUP_ID"];
                sdafControlPlaneEnvironment = configuration["CONTROLPLANE_ENV"];
                sdafControlPlaneLocation = configuration["CONTROLPLANE_LOC"];
                tenantId = configuration["AZURE_TENANT_ID"];
                ghOrgAndRepository = configuration["GITHUB_REPOSITORY"];

                managedIdentityClientId = configuration["OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"];

                jsonSerializerOptions = new JsonSerializerOptions() { IgnoreNullValues = true };

                LogDebug($"Initialized for {type}");
                LogDebug($"CollectionUri: {collectionUri}");
                LogDebug($"Project: {project}");
                LogDebug($"RepositoryId: {repositoryId}");
                LogDebug($"RepoType: {repoType}");
                LogDebug($"Branch: {branch}");
                LogDebug($"SDAF General Group Id: {sdafGeneralId}");
                LogDebug($"Control Plane Environment: {sdafControlPlaneEnvironment}");
                LogDebug($"Control Plane Location: {sdafControlPlaneLocation}");
                LogDebug($"Authentication: {devops_authentication}");
                LogDebug($"Managed Identity Tenant configured: {!string.IsNullOrEmpty(tenantId)}");
                LogDebug($"Managed Identity Client Id configured: {!string.IsNullOrEmpty(managedIdentityClientId)}");
                LogDebug($"GitHub repository configured: {!string.IsNullOrEmpty(ghOrgAndRepository)}");
            }
            catch (KeyNotFoundException ex)
            {
                LogDebug($"ERROR: Configuration key not found: {ex.Message}");
                throw new InvalidOperationException(
                    $"Missing required configuration for ADO/GitHub: {ex.Message}. " +
                    $"Ensure CollectionUri, ProjectName, RepositoryId, and authentication settings are configured.",
                    ex);
            }
            catch (Exception ex)
            {
                LogDebug($"ERROR: Initialization failed: {ex.Message}");
                throw;
            }

            if (repoType.ToLower() == "ado")
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

                    var tokenRequestContext = new TokenRequestContext(new[] { "499b84ac-1321-427f-aa17-267ca6975798/.default" });
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
            else if (repoType.ToLower() == "github")
            {
                if (ghOrgAndRepository.Length > 0)
                {
                    ghOrganization = ghOrgAndRepository.Split("/")[0];
                    ghRepository = ghOrgAndRepository.Split("/")[1];
                    ghToken = configuration["GITHUB_PAT"];
                }
                else
                {
                    throw new ArgumentNullException("GitHub repository must be provided for GitHub operations.");

                }

                client = new HttpClient();

                client.DefaultRequestHeaders.Accept.Add(
                    new MediaTypeWithQualityHeaderValue("application/json"));

                client.DefaultRequestHeaders.Add("User-Agent", "sap-automation");
                client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("SDAF", "1.0"));
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", ghToken);
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));


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
            LogDebug("GetProjectId called");
            string getUri = $"{collectionUri}_apis/projects/{project}?api-version=7.1";
            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

            return JsonDocument.Parse(responseBody).RootElement.GetProperty("id").GetString();
        }

        // Add or edit a file in ADO
        public async Task UpdateRepo(string path, string content)
        {
            LogDebug($"UpdateRepo called. RepoType={repoType}, Path={path}, ContentLength={content?.Length ?? 0}");
            if (repoType.ToLower() == "ado")
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
                path = ComposeRepositoryPath(pathBase, path);

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
            else
            {
                path = ComposeRepositoryPath("WORKSPACES", path);
                var uploader = new GitHubFileUploader(ghToken, ghOrganization, ghRepository);
                while (path.StartsWith("/"))
                {
                    path = path.Substring(1);
                }
                var changeSet = await uploader.CreateOrUpdateFileAsync(path, content, "Update file via SDAF App Service", "main");
                if (changeSet == null || changeSet.Content == null)
                {
                    throw new HttpRequestException("Failed to create or update the file on GitHub.");
                }
            }
        }

        // Trigger a pipeline in azure devops
        public async Task TriggerPipeline(string pipelineId, PipelineRequestBody requestBody)
        {
            LogDebug($"TriggerPipeline called. PipelineId={pipelineId}, Branch={branch}");
            string getUri = $"{collectionUri}{project}/_apis/pipelines/{pipelineId}";
            using HttpResponseMessage getResponse = client.GetAsync(getUri).Result;
            string getResponseBody = await getResponse.Content.ReadAsStringAsync();
            HandleResponse(getResponse, getResponseBody);

            string postUri = $"{collectionUri}{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1";

            string requestJson = JsonSerializer.Serialize(requestBody, typeof(PipelineRequestBody), jsonSerializerOptions);
            using StringContent content = new(requestJson, Encoding.UTF8, "application/json");

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);
        }

        // Add this method to the RestHelper class to trigger a GitHub Action workflow

        public async Task TriggerGitHubWorkflow(string workflowFileName, string branch = "main", Dictionary<string, object> inputs = null)
        {
            LogDebug($"TriggerGitHubWorkflow called. Workflow={workflowFileName}, Branch={branch}, InputCount={inputs?.Count ?? 0}");
            var githubClient = new Octokit.GitHubClient(new Octokit.ProductHeaderValue("SDAF"));
            githubClient.Credentials = new Octokit.Credentials(ghToken);

            var workflowDispatch = new Octokit.CreateWorkflowDispatch(branch)
            {
                Inputs = inputs ?? new Dictionary<string, object>()
            };

            try
            {
                await githubClient.Actions.Workflows.CreateDispatch(ghOrganization, ghRepository, workflowFileName, workflowDispatch);
            }
            catch (Octokit.ApiException ex)
            {
                throw new HttpRequestException($"Failed to trigger GitHub workflow: {ex.Message}");
            }
        }

        // Get an array of file names from azure sap-automation region given a directory
        public async Task<string[]> GetTemplateFileNames(string scopePath)
        {
            LogDebug($"GetTemplateFileNames called. ScopePath={scopePath}");
            string getUri = $"{sampleUrl}/contents/{scopePath}?ref=main";

            //if (!string.IsNullOrEmpty(ghToken))
            //{
            //    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", ghToken);
            //    getUri += "&access_token=ghToken";
            //}
            try
            {
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
            catch (AggregateException ex)
            {
                throw new HttpRequestException($"Error fetching template file names: {ex.Message}");
            }
            catch (HttpRequestException ex)
            {
                throw new HttpRequestException($"Error fetching template file names: {ex.Message}");
            }

        }

        // Get a file from azure sap-automation repository
        public async Task<string> GetTemplateFile(string path)
        {
            LogDebug($"GetTemplateFile called. Path={path}");
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
            LogDebug("GetVariableGroupsJson called");
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
            LogDebug("GetVariableGroups called");
            if (repoType.ToLower() == "ado")
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
            else
            {
                return [];
            }
        }

        // Get a list of all variable group names for use in a dropdown
        public async Task<List<SelectListItem>> GetEnvironmentsList()
        {
            LogDebug("GetEnvironmentsList called");
            List<SelectListItem> variableGroups = [ new SelectListItem { Text = "", Value = "" } ];
            switch (repoType.ToLower())
            {
                case "github":
                    {
                        var helper = new GitHubEnvironmentHelper(ghToken, ghOrganization, ghRepository);
                        // FIX: Await the async method and use the result directly
                        var environments = await helper.ListEnvironmentsAsync();

                        foreach (var env in environments)
                        {
                            string groupName = env.Name;
                            variableGroups.Add(new SelectListItem
                            {
                                Text = groupName,
                                Value = groupName
                            });

                        }
                        break;
                    }
                case "ado":
                    {
                        JsonElement values = await GetVariableGroupsJson();

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

                        break;
                    }

            }
            return variableGroups;
        }

        // Get a specific variable group from azure devops
        public async Task<EnvironmentModel> GetVariableGroup(int id)
        {
            LogDebug($"GetVariableGroup called. Id={id}");
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
            LogDebug($"GetVariableGroupIdFromName called. Name={name}");
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
            LogDebug($"GetVariableFromVariableGroup called. Id={id}, Group={variableGroupName}, Variable={variableName}");
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
            // Intentional fallback: swallow lookup failures and return the default workspace name.
            catch
            {
                return "WORKSPACES";
            }
        }

        // Create a variable group in azure devops
        public async Task CreateVariableGroup(EnvironmentModel environment, string newName, string description)
        {
            LogDebug($"CreateVariableGroup called. Name={newName}");
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
            using StringContent content = new(requestJson, Encoding.ASCII, "application/json");

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            string responseBody = await response.Content.ReadAsStringAsync();
            HandleResponse(response, responseBody);

        }

        // Update a variable group in azure devops
        public async Task UpdateVariableGroup(EnvironmentModel environment, string newName, string description)
        {
            LogDebug($"UpdateVariableGroup called. Id={environment?.id}, NewName={newName}");
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
            dynamicVariables.ARM_USE_MSI = JToken.FromObject(environment.variables.ARM_USE_MSI);
            dynamicVariables.USE_MSI = JToken.FromObject(environment.variables.ARM_USE_MSI);
            dynamicVariables.DNS_NAME = JToken.FromObject(environment.variables.DNS_NAME);
            dynamicVariables.POOL = JToken.FromObject(environment.variables.POOL);
            dynamicVariables.CONTROL_PLANE_NAME = JToken.FromObject(environment.variables.CONTROL_PLANE_NAME);
            dynamicVariables.DEPLOYER_KEYVAULT = JToken.FromObject(environment.variables.DEPLOYER_KEYVAULT);
            dynamicVariables.TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME = JToken.FromObject(environment.variables.TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME);
            dynamicVariables.TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION = JToken.FromObject(environment.variables.TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION);
            dynamicVariables.APPLICATION_CONFIGURATION_NAME = JToken.FromObject(environment.variables.APPLICATION_CONFIGURATION_NAME);


            dynamicEnvironment.variables = dynamicVariables;

            string mergedJson = JsonConvert.SerializeObject(dynamicEnvironment, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
            using JsonDocument mergedDocument = JsonDocument.Parse(mergedJson);
            string requestJson = JsonSerializer.Serialize(mergedDocument.RootElement, jsonSerializerOptions);
            using StringContent content = new(requestJson, Encoding.UTF8, "application/json");

            HttpResponseMessage putResponse = await client.PutAsync(uri, content);
            string putResponseBody = await putResponse.Content.ReadAsStringAsync();
            HandleResponse(putResponse, putResponseBody);
        }

        // Repository read operations: Get file content from repository (ADO or GitHub)
        public async Task<RepositoryFileResponse> GetRepositoryFileAsync(string path)
        {
            LogDebug($"GetRepositoryFileAsync called. RepoType={repoType}, Path={path}");
            try
            {
                if (repoType.ToLower() == "ado")
                {
                    return await GetAdoFileAsync(path);
                }
                else if (repoType.ToLower() == "github")
                {
                    return await GetGitHubFileAsync(path);
                }
                else
                {
                    throw new RepositoryOperationException(
                        $"Unsupported repository type: {repoType}",
                        RepositoryErrorCategory.ValidationError);
                }
            }
            catch (RepositoryOperationException)
            {
                throw;
            }
            catch (HttpRequestException ex)
            {
                throw new RepositoryOperationException(
                    $"Failed to read file '{path}' from repository: {ex.Message}",
                    RepositoryErrorCategory.TransientError,
                    isTransient: true,
                    innerException: ex);
            }
            catch (Exception ex)
            {
                throw new RepositoryOperationException(
                    $"Unexpected error reading file '{path}': {ex.Message}",
                    RepositoryErrorCategory.Unknown,
                    innerException: ex);
            }
        }

        private async Task<RepositoryFileResponse> GetAdoFileAsync(string path)
        {
            // First get the objectId from the items endpoint
            string getItemsUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/items?scopePath={System.Web.HttpUtility.UrlEncode(path)}&recursionLevel=0&api-version=7.1";
            System.Diagnostics.Debug.WriteLine($"[GetAdoFileAsync] Getting objectId from: {getItemsUri}");

            string objectId = null;
            using (HttpResponseMessage itemsResponse = await client.GetAsync(getItemsUri))
            {
                if (itemsResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    throw new RepositoryOperationException(
                        $"File not found: {path}",
                        RepositoryErrorCategory.NotFound,
                        statusCode: 404);
                }

                if (!itemsResponse.IsSuccessStatusCode)
                {
                    string responseBody = await itemsResponse.Content.ReadAsStringAsync();
                    throw new RepositoryOperationException(
                        $"Failed to get file objectId: {responseBody}",
                        GetErrorCategory(itemsResponse.StatusCode),
                        statusCode: (int)itemsResponse.StatusCode,
                        isTransient: IsTransientStatusCode(itemsResponse.StatusCode));
                }

                string itemsContent = await itemsResponse.Content.ReadAsStringAsync();
                JsonElement itemsRoot = JsonDocument.Parse(itemsContent).RootElement;

                // Items API returns response with "count" and "value" array
                if (itemsRoot.TryGetProperty("value", out var valueArray) && valueArray.GetArrayLength() > 0)
                {
                    var firstItem = valueArray[0];
                    if (firstItem.TryGetProperty("objectId", out var objectIdElem))
                    {
                        objectId = objectIdElem.GetString();
                        System.Diagnostics.Debug.WriteLine($"[GetAdoFileAsync] Got objectId for {path}: {objectId}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"[GetAdoFileAsync] No objectId in first item for {path}. Item properties: {string.Join(", ", firstItem.EnumerateObject().Select(p => p.Name))}");
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine($"[GetAdoFileAsync] No value array or empty array in items response for {path}. Root properties: {string.Join(", ", itemsRoot.EnumerateObject().Select(p => p.Name))}");
                }

                if (string.IsNullOrEmpty(objectId))
                {
                    throw new RepositoryOperationException(
                        $"Cannot find objectId for file '{path}'",
                        RepositoryErrorCategory.Unknown);
                }
            } // Close the using block for itemsResponse

            // Now call Blobs API to get the file content
            // Use $format=text to get raw file content instead of JSON metadata
            string getBlobUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/blobs/{System.Web.HttpUtility.UrlEncode(objectId)}?$format=text&api-version=7.1";
            System.Diagnostics.Debug.WriteLine($"[GetAdoFileAsync] Getting blob content from: {getBlobUri}");

            using HttpResponseMessage blobResponse = await client.GetAsync(getBlobUri);
            if (blobResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                throw new RepositoryOperationException(
                    $"Blob not found: {objectId}",
                    RepositoryErrorCategory.NotFound,
                    statusCode: 404);
            }

            if (!blobResponse.IsSuccessStatusCode)
            {
                string responseBody = await blobResponse.Content.ReadAsStringAsync();
                throw new RepositoryOperationException(
                    $"Failed to get blob content: {responseBody}",
                    GetErrorCategory(blobResponse.StatusCode),
                    statusCode: (int)blobResponse.StatusCode,
                    isTransient: IsTransientStatusCode(blobResponse.StatusCode));
            }

            string blobContent = await blobResponse.Content.ReadAsStringAsync();
            System.Diagnostics.Debug.WriteLine($"[GetAdoFileAsync] Successfully retrieved blob content for {path}");

            return new RepositoryFileResponse
            {
                Path = path,
                Content = blobContent,
                ContentBytes = System.Text.Encoding.UTF8.GetBytes(blobContent),
                Exists = true,
                LastModified = DateTimeOffset.UtcNow
            };
        }

        private async Task<RepositoryFileResponse> GetGitHubFileAsync(string path)
        {
            string encodedPath = System.Web.HttpUtility.UrlEncode(path);
            string getUri = $"https://api.github.com/repos/{ghOrganization}/{ghRepository}/contents/{encodedPath}";

            using HttpResponseMessage response = await client.GetAsync(getUri);
            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                throw new RepositoryOperationException(
                    $"File not found: {path}",
                    RepositoryErrorCategory.NotFound,
                    statusCode: 404);
            }

            if (!response.IsSuccessStatusCode)
            {
                string responseBody = await response.Content.ReadAsStringAsync();
                throw new RepositoryOperationException(
                    $"Failed to read GitHub file: {responseBody}",
                    GetErrorCategory(response.StatusCode),
                    statusCode: (int)response.StatusCode,
                    isTransient: IsTransientStatusCode(response.StatusCode));
            }

            string responseContent = await response.Content.ReadAsStringAsync();
            JsonElement root = JsonDocument.Parse(responseContent).RootElement;

            string encodedContent = root.GetProperty("content").GetString();
            byte[] contentBytes = Convert.FromBase64String(encodedContent);

            return new RepositoryFileResponse
            {
                Path = path,
                Content = Encoding.UTF8.GetString(contentBytes),
                ContentBytes = contentBytes,
                CommitSha = root.GetProperty("sha").GetString(),
                Exists = true,
                LastModified = DateTimeOffset.UtcNow
            };
        }

        // Repository list operations: List files recursively in a directory
        public async Task<RepositoryListResponse> ListRepositoryFilesAsync(string directoryPath)
        {
            LogDebug($"ListRepositoryFilesAsync called. RepoType={repoType}, DirectoryPath={directoryPath}");
            try
            {
                if (repoType.ToLower() == "ado")
                {
                    return await ListAdoFilesAsync(directoryPath);
                }
                else if (repoType.ToLower() == "github")
                {
                    return await ListGitHubFilesAsync(directoryPath);
                }
                else
                {
                    throw new RepositoryOperationException(
                        $"Unsupported repository type: {repoType}",
                        RepositoryErrorCategory.ValidationError);
                }
            }
            catch (RepositoryOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                throw new RepositoryOperationException(
                    $"Failed to list files in '{directoryPath}': {ex.Message}",
                    RepositoryErrorCategory.TransientError,
                    isTransient: true,
                    innerException: ex);
            }
        }

        private async Task<RepositoryListResponse> ListAdoFilesAsync(string directoryPath)
        {
            var response = new RepositoryListResponse();

            // Validate configuration
            if (string.IsNullOrWhiteSpace(collectionUri) ||
                string.IsNullOrWhiteSpace(project) ||
                string.IsNullOrWhiteSpace(repositoryId))
            {
                throw new InvalidOperationException(
                    $"ADO configuration incomplete. CollectionUri={collectionUri}, " +
                    $"Project={project}, RepositoryId={repositoryId}");
            }

            string getUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/items?scopePath={System.Web.HttpUtility.UrlEncode(directoryPath)}&recursionLevel=1&api-version=7.1";

            System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Calling URI: {getUri}");

            using HttpResponseMessage httpResponse = await client.GetAsync(getUri);
            if (!httpResponse.IsSuccessStatusCode)
            {
                string responseBody = await httpResponse.Content.ReadAsStringAsync();
                System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] HTTP Error {httpResponse.StatusCode}: {responseBody}");
                throw new RepositoryOperationException(
                    $"Failed to list ADO files: {responseBody}",
                    GetErrorCategory(httpResponse.StatusCode),
                    statusCode: (int)httpResponse.StatusCode);
            }

            string content = await httpResponse.Content.ReadAsStringAsync();

            // Debug logging
            System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Response length: {content.Length} bytes");
            System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Response: {content.Substring(0, Math.Min(500, content.Length))}...");

            JsonElement root = JsonDocument.Parse(content).RootElement;

            if (root.TryGetProperty("value", out var items))
            {
                int totalItems = items.GetArrayLength();
                System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Found 'value' property with {totalItems} items");

                int itemsAdded = 0;
                foreach (var item in items.EnumerateArray())
                {
                    // Safely get path property
                    if (!item.TryGetProperty("path", out var pathElem))
                    {
                        System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Skipping item - no path property");
                        continue; // Skip items without path
                    }
                    string itemPath = pathElem.GetString();

                    // Safely get isFolder property (default to false if not present)
                    bool isFolder = false;
                    if (item.TryGetProperty("isFolder", out var isFolderElem))
                    {
                        isFolder = isFolderElem.GetBoolean();
                    }

                    System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Item: path='{itemPath}' isFolder={isFolder}");

                    if (isFolder)
                    {
                        response.Items.Add(new RepositoryListItem
                        {
                            Path = itemPath,
                            Name = System.IO.Path.GetFileName(itemPath),
                            IsDirectory = true
                        });
                        itemsAdded++;
                    }
                    else
                    {
                        response.Items.Add(new RepositoryListItem
                        {
                            Path = itemPath,
                            Name = System.IO.Path.GetFileName(itemPath),
                            IsDirectory = false,
                            Size = item.TryGetProperty("size", out var sizeElem) && sizeElem.TryGetInt64(out long size) ? size : null
                        });
                        itemsAdded++;
                    }
                }
                System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Added {itemsAdded} items to response (out of {totalItems} from API)");
            }
            else
            {
                System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] No 'value' property found in response");
                System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Root properties: {string.Join(", ", root.EnumerateObject().Select(p => p.Name))}");
            }

            System.Diagnostics.Debug.WriteLine($"[ADO ListFiles] Returning {response.Items.Count} items");
            return response;
        }

        private async Task<RepositoryListResponse> ListGitHubFilesAsync(string directoryPath)
        {
            var response = new RepositoryListResponse();
            string encodedPath = System.Web.HttpUtility.UrlEncode(directoryPath.TrimStart('/'));
            string getUri = $"https://api.github.com/repos/{ghOrganization}/{ghRepository}/contents/{encodedPath}";

            using HttpResponseMessage httpResponse = await client.GetAsync(getUri);
            if (httpResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                // Directory doesn't exist, return empty list
                return response;
            }

            if (!httpResponse.IsSuccessStatusCode)
            {
                string responseBody = await httpResponse.Content.ReadAsStringAsync();
                throw new RepositoryOperationException(
                    $"Failed to list GitHub files: {responseBody}",
                    GetErrorCategory(httpResponse.StatusCode),
                    statusCode: (int)httpResponse.StatusCode);
            }

            string content = await httpResponse.Content.ReadAsStringAsync();
            JsonElement root = JsonDocument.Parse(content).RootElement;

            if (root.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in root.EnumerateArray())
                {
                    string itemPath = item.GetProperty("path").GetString();
                    string itemType = item.GetProperty("type").GetString();

                    response.Items.Add(new RepositoryListItem
                    {
                        Path = itemPath,
                        Name = item.GetProperty("name").GetString(),
                        IsDirectory = itemType == "dir",
                        Size = item.TryGetProperty("size", out var sizeElem) && sizeElem.TryGetInt64(out long size) ? size : null,
                        CommitSha = item.TryGetProperty("sha", out var shaElem) ? shaElem.GetString() : null
                    });
                }
            }

            return response;
        }

        // Repository delete operations: Delete a file and create a commit
        public async Task DeleteRepositoryFileAsync(RepositoryDeleteRequest request)
        {
            LogDebug($"DeleteRepositoryFileAsync called. RepoType={repoType}, Path={request?.Path}");
            try
            {
                if (repoType.ToLower() == "ado")
                {
                    await DeleteAdoFileAsync(request);
                }
                else if (repoType.ToLower() == "github")
                {
                    await DeleteGitHubFileAsync(request);
                }
                else
                {
                    throw new RepositoryOperationException(
                        $"Unsupported repository type: {repoType}",
                        RepositoryErrorCategory.ValidationError);
                }
            }
            catch (RepositoryOperationException)
            {
                throw;
            }
            catch (HttpRequestException ex)
            {
                throw new RepositoryOperationException(
                    $"Failed to delete file '{request.Path}': {ex.Message}",
                    RepositoryErrorCategory.TransientError,
                    isTransient: true,
                    innerException: ex);
            }
        }

        private async Task DeleteAdoFileAsync(RepositoryDeleteRequest request)
        {
            string getUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/refs/?filter=heads/{branch}";
            string postUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/pushes?api-version=5.1";

            using HttpResponseMessage refResponse = await client.GetAsync(getUri);
            if (!refResponse.IsSuccessStatusCode)
            {
                string responseBody = await refResponse.Content.ReadAsStringAsync();
                throw new RepositoryOperationException(
                    $"Failed to get branch ref: {responseBody}",
                    RepositoryErrorCategory.TransientError,
                    isTransient: true);
            }

            string refContent = await refResponse.Content.ReadAsStringAsync();
            string ooId = JsonDocument.Parse(refContent).RootElement.GetProperty("value")[0].GetProperty("objectId").GetString();

            string pathBase = await GetVariableFromVariableGroup(sdafGeneralId, "SDAF-General", "Deployment_Configuration_Path");
            string fullPath = ComposeRepositoryPath(pathBase, request.Path);

            Refupdate refUpdate = new()
            {
                name = $"refs/heads/{branch}",
                oldObjectId = ooId
            };

            Change change = new()
            {
                changeType = "delete",
                item = new() { path = fullPath }
            };

            Models.Commit commit = new()
            {
                comment = request.CommitMessage ?? "Delete file via SDAF App Service",
                changes = new[] { change }
            };

            GitRequestBody deleteRequest = new()
            {
                refUpdates = new[] { refUpdate },
                commits = new[] { commit }
            };

            string requestJson = JsonSerializer.Serialize(deleteRequest, jsonSerializerOptions);
            StringContent content = new(requestJson, Encoding.UTF8, "application/json");

            using HttpResponseMessage deleteResponse = await client.PostAsync(postUri, content);
            if (!deleteResponse.IsSuccessStatusCode)
            {
                string responseBody = await deleteResponse.Content.ReadAsStringAsync();
                throw new RepositoryOperationException(
                    $"Failed to delete ADO file: {responseBody}",
                    GetErrorCategory(deleteResponse.StatusCode),
                    statusCode: (int)deleteResponse.StatusCode);
            }
        }

        private static string ComposeRepositoryPath(string basePath, string path)
        {
            string normalizedBase = (basePath ?? string.Empty).Replace('\\', '/').Trim('/');
            string normalizedPath = (path ?? string.Empty).Replace('\\', '/').Trim();

            while (normalizedPath.StartsWith('/'))
            {
                normalizedPath = normalizedPath[1..];
            }

            if (string.IsNullOrEmpty(normalizedBase))
            {
                return normalizedPath;
            }

            if (string.IsNullOrEmpty(normalizedPath))
            {
                return normalizedBase;
            }

            if (normalizedPath.Equals(normalizedBase, StringComparison.OrdinalIgnoreCase) ||
                normalizedPath.StartsWith(normalizedBase + "/", StringComparison.OrdinalIgnoreCase))
            {
                return normalizedPath;
            }

            return normalizedBase + "/" + normalizedPath;
        }

        private async Task DeleteGitHubFileAsync(RepositoryDeleteRequest request)
        {
            var fileResponse = await GetGitHubFileAsync(request.Path);
            if (!fileResponse.Exists)
            {
                throw new RepositoryOperationException(
                    $"File not found: {request.Path}",
                    RepositoryErrorCategory.NotFound,
                    statusCode: 404);
            }

            string encodedPath = System.Web.HttpUtility.UrlEncode(request.Path);
            string deleteUri = $"https://api.github.com/repos/{ghOrganization}/{ghRepository}/contents/{encodedPath}";

            var deletePayload = new
            {
                message = request.CommitMessage ?? "Delete file via SDAF App Service",
                sha = fileResponse.CommitSha,
                branch = branch
            };

            string requestJson = JsonSerializer.Serialize(deletePayload, jsonSerializerOptions);
            var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, deleteUri)
            {
                Content = new StringContent(requestJson, Encoding.UTF8, "application/json")
            };

            using HttpResponseMessage response = await client.SendAsync(deleteRequest);
            if (!response.IsSuccessStatusCode)
            {
                string responseBody = await response.Content.ReadAsStringAsync();
                throw new RepositoryOperationException(
                    $"Failed to delete GitHub file: {responseBody}",
                    GetErrorCategory(response.StatusCode),
                    statusCode: (int)response.StatusCode);
            }
        }

        // Repository file existence check: Optimized check without full content read
        public async Task<bool> RepositoryFileExistsAsync(string path)
        {
            LogDebug($"RepositoryFileExistsAsync called. RepoType={repoType}, Path={path}");
            try
            {
                if (repoType.ToLower() == "ado")
                {
                    return await AdoFileExistsAsync(path);
                }
                else if (repoType.ToLower() == "github")
                {
                    return await GitHubFileExistsAsync(path);
                }
                return false;
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                return false;
            }
            catch
            {
                return false;
            }
        }

        private async Task<bool> AdoFileExistsAsync(string path)
        {
            string getUri = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/items?scopePath={System.Web.HttpUtility.UrlEncode(path)}&api-version=7.1";

            using HttpResponseMessage response = await client.GetAsync(getUri);
            return response.IsSuccessStatusCode;
        }

        private async Task<bool> GitHubFileExistsAsync(string path)
        {
            string encodedPath = System.Web.HttpUtility.UrlEncode(path);
            string getUri = $"https://api.github.com/repos/{ghOrganization}/{ghRepository}/contents/{encodedPath}";

            using HttpResponseMessage response = await client.GetAsync(getUri);
            return response.IsSuccessStatusCode;
        }

        // Helper methods for error categorization and transient detection
        private static RepositoryErrorCategory GetErrorCategory(System.Net.HttpStatusCode statusCode)
        {
            return statusCode switch
            {
                System.Net.HttpStatusCode.NotFound => RepositoryErrorCategory.NotFound,
                System.Net.HttpStatusCode.Unauthorized or System.Net.HttpStatusCode.Forbidden => RepositoryErrorCategory.AuthenticationError,
                System.Net.HttpStatusCode.Conflict => RepositoryErrorCategory.Conflict,
                System.Net.HttpStatusCode.BadRequest => RepositoryErrorCategory.ValidationError,
                System.Net.HttpStatusCode.InternalServerError or System.Net.HttpStatusCode.ServiceUnavailable or System.Net.HttpStatusCode.GatewayTimeout => RepositoryErrorCategory.TransientError,
                _ => RepositoryErrorCategory.Unknown
            };
        }

        private static bool IsTransientStatusCode(System.Net.HttpStatusCode statusCode)
        {
            return statusCode switch
            {
                System.Net.HttpStatusCode.RequestTimeout or
                System.Net.HttpStatusCode.InternalServerError or
                System.Net.HttpStatusCode.BadGateway or
                System.Net.HttpStatusCode.ServiceUnavailable or
                System.Net.HttpStatusCode.GatewayTimeout => true,
                _ => false
            };
        }

        static private void HandleResponse(HttpResponseMessage response, string responseBody)
        {
            
            LogDebug($"HandleResponse: StatusCode={response.StatusCode}");
            if (!response.IsSuccessStatusCode)
            {
                string errorMessage = JsonDocument.Parse(responseBody).RootElement.GetProperty("message").ToString();
                switch (response.StatusCode)
                {
                    
                    case System.Net.HttpStatusCode.Unauthorized:
                        errorMessage = "Unauthorized, please ensure that the MSI/Personal Access Token has sufficient permissions and that it has not expired.";
                        break;
                    case System.Net.HttpStatusCode.NotFound:
                        errorMessage = "Could not find the template.";
                        break;
                    default:

                        if (errorMessage.Contains("Resource protected by organization SAML"))
                        {

                        }
                        else
                        {
                            LogDebug($"HandleResponse: StatusCode={response.StatusCode} ErrorMessage={errorMessage}");
                        }
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
