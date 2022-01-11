using Microsoft.AspNetCore.Mvc;
using AutomationForm.Models;
using System.Text.Json;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;
using System.Text;
using System.Net.Http;
using Microsoft.Extensions.Configuration;
using System.Net.Http.Headers;

namespace AutomationForm.Controllers
{
    public class HelperController<T> : Controller
    {
        public string ConvertToTerraform(T model)
        {
            StringBuilder str = new StringBuilder();
            foreach (var property in model.GetType().GetProperties())
            {
                if (property.Name == "Id") continue;
                var value = property.GetValue(model);
                if (value != null)
                {
                    if (property.PropertyType.IsArray)
                    {
                        str.Append(property.Name + " = [");
                        foreach (var val in (string[]) value)
                        {
                            str.Append($"\"{val}\", ");
                        }
                        str.Remove(str.Length - 2, 2);
                        str.AppendLine("]");
                    }
                    else if (property.PropertyType == typeof(Image))
                    {
                        Image img = (Image)value;
                        str.AppendLine(property.Name + " = {");
                        str.AppendLine("  os_type="           + $"\"{img.os_type}\",");
                        str.AppendLine("  source_image_id="   + $"\"{img.source_image_id}\",");
                        str.AppendLine("  publisher="         + $"\"{img.publisher}\",");
                        str.AppendLine("  offer="             + $"\"{img.offer}\",");
                        str.AppendLine("  sku="               + $"\"{img.sku}\",");
                        str.AppendLine("}");
                    }
                    else
                    {
                        str.AppendLine(property.Name + " = " + $"\"{value}\"");
                    }
                }
            }
            return str.ToString();
        }
        public async Task UpdateRepo(string path, string content, IConfiguration configuration)
        {
            string collectionUri    = configuration["CollectionUri"];
            string project          = configuration["Project"];
            string repositoryId     = configuration["RepositoryId"];
            string PAT              = configuration["PAT"];
            string getUri           = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/refs/?filter=heads/private-preview";
            string postUri          = $"{collectionUri}{project}/_apis/git/repositories/{repositoryId}/pushes?api-version=5.1";
            string ooId;

            // CONFIGURE HTTP CLIENT

            using HttpClient client = new HttpClient();
            client.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic",
                Convert.ToBase64String(
                    System.Text.ASCIIEncoding.ASCII.GetBytes(
                        string.Format("{0}:{1}", "", PAT))));
            
            // SET THE MAIN BRANCH OBJECT ID

            using HttpResponseMessage response = client.GetAsync(getUri).Result;
            response.EnsureSuccessStatusCode();
            string responseBody = await response.Content.ReadAsStringAsync();
            RefModel branchData = JsonSerializer.Deserialize<RefModel>(responseBody);
            ooId = branchData.value[0].objectId;

            // CREATE REQUEST BODY AND UPDATE

            Refupdate refUpdate = new Refupdate()
            {
                name = "refs/heads/private-preview",
                oldObjectId = ooId
            };
            GitRequestBody requestBody = new GitRequestBody()
            {
                refUpdates = new Refupdate[] { refUpdate },
            };
            StringContent editContent = CreateHttpContent("edit", path, content, requestBody);
            
            // try to edit file (if it exists)
            HttpResponseMessage editResponse = await client.PostAsync(postUri, editContent);

            // add file on unsuccessful edit (because it does not exist)
            if (!editResponse.IsSuccessStatusCode)
            {
                StringContent addContent = CreateHttpContent("add", path, content, requestBody);
                HttpResponseMessage addResponse = await client.PostAsync(postUri, addContent);
                addResponse.EnsureSuccessStatusCode();
            }
        }
        public StringContent CreateHttpContent(string changeType, string path, string content, GitRequestBody requestBody)
        {
            Commit commit = new Commit()
            {
                comment = $"{changeType}ed {path}",
                changes = new Change[]
                {
                    new Change()
                    {
                        changeType = changeType,
                        item = new Item()
                        {
                            path = path,
                        },
                        newContent = new Newcontent()
                        {
                            content = content,
                            contentType = "rawtext"
                        }
                    }
                }
            };
            requestBody.commits = new Commit[] { commit };
            string requestJson = JsonSerializer.Serialize(requestBody);
            return new StringContent(requestJson, Encoding.ASCII, "application/json");
        }
        public async Task TriggerPipeline(string pipelineId, IConfiguration configuration)
        {
            string collectionUri    = configuration["CollectionUri"];
            string project          = configuration["Project"];
            string PAT              = configuration["PAT"];
            string postUri          = $"{collectionUri}{project}/_apis/pipelines/{pipelineId}/runs?api-version=6.0-preview.1";

            // CONFIGURE HTTP CLIENT

            using HttpClient client = new HttpClient();
            client.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic",
                Convert.ToBase64String(
                    System.Text.ASCIIEncoding.ASCII.GetBytes(
                        string.Format("{0}:{1}", "", PAT))));

            // CREATE REQUEST BODY

            PipelineRequestBody requestBody = new PipelineRequestBody
            {
                resources = new Resources { 
                    repositories = new Repositories {
                        self = new Self {
                            refName = "refs/heads/private-preview"
                        }
                    }
                }
            };
            string requestJson = JsonSerializer.Serialize(requestBody);
            Console.WriteLine(requestJson);
            StringContent content = new StringContent(requestJson, Encoding.ASCII, "application/json");

            // TRIGGER PIPELINE

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            Console.WriteLine(response.Content.ReadAsStringAsync().Result);
            response.EnsureSuccessStatusCode();
        }
        public ParameterGroupingModel ReadJson(string filename)
        {
            if (System.IO.File.Exists(filename))
            {
                string jsonString = System.IO.File.ReadAllText(filename);
                ParameterGroupingModel parameterArray = JsonSerializer.Deserialize<ParameterGroupingModel>(jsonString);

                return parameterArray;
            }
            else
            {
                throw new System.IO.DirectoryNotFoundException();
            }
        }
        public string mapRegion(string region)
        {
            Dictionary<string, string> regionMapping = new Dictionary<string, string>()
            {
                {"westus", "weus" },
                {"westus2", "wus2" },
                {"centralus", "ceus" },
                {"eastus", "eaus" },
                {"eastus2", "eus2" },
                {"northcentralus", "ncus" },
                {"southcentralus", "scus" },
                {"westcentralus", "wcus" },
                {"northeurope", "noeu" },
                {"westeurope", "weeu" },
                {"eastasia", "eeas" },
                {"southeastasia", "seas" },
                {"brazilsouth", "brso" },
                {"japaneast", "jpea" },
                {"japanwest", "jpwe" },
                {"centralindia", "cein" },
                {"southindia", "soin" },
                {"westindia", "wein" },
                {"uksouth2", "uks2" },
                {"uknorth", "ukno" },
                {"canadacentral", "cace" },
                {"canadaeast", "caea" },
                {"australiaeast", "auea" },
                {"australiasoutheast", "ause" },
                {"uksouth", "ukso" },
                {"ukwest", "ukwe" },
                {"koreacentral", "koce" },
                {"koreasouth", "koso" },
            };
            if (regionMapping.ContainsKey(region))
            {
                return regionMapping[region];
            }
            return region;
        }
    }
}
