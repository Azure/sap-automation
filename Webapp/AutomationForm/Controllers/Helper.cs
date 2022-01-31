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
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using System.Reflection;
using System.ComponentModel.DataAnnotations;
using System.Net;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace AutomationForm.Controllers
{
    public class Helper : Controller
    {
        private static readonly Dictionary<string, string> regionMapping = new Dictionary<string, string>()
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
        public static string ConvertToTerraform<T>(T model)
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
                    else if (property.PropertyType == typeof(bool?))
                    {
                        bool b = (bool)value;
                        str.AppendLine(property.Name + " = " + b.ToString().ToLower());
                    }
                    else if (property.PropertyType == typeof(int?))
                    {
                        int i = (int)value;
                        str.AppendLine(property.Name + " = " + i);
                    }
                    else
                    {
                        str.AppendLine(property.Name + " = " + $"\"{value}\"");
                    }
                }
            }
            return str.ToString();
        }
        public static async Task UpdateRepo(string path, string content, IConfiguration configuration)
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
        private static StringContent CreateHttpContent(string changeType, string path, string content, GitRequestBody requestBody)
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
        public static async Task TriggerPipeline(string pipelineId, string id, IConfiguration configuration, bool isSystem, string environment, string workload_environment)
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
            if (isSystem)
            {
                requestBody.templateParameters = new Templateparameters {
                    sap_system = id,
                    environment = workload_environment
                };
            }
            else
            {
                requestBody.templateParameters = new Templateparameters {
                    workloadzone = id,
                    environment = environment,
                    workload_environment = workload_environment
                };
            }
            string requestJson = JsonSerializer.Serialize(requestBody, typeof(PipelineRequestBody), new JsonSerializerOptions() { IgnoreNullValues = true });
            StringContent content = new StringContent(requestJson, Encoding.ASCII, "application/json");

            // TRIGGER PIPELINE

            HttpResponseMessage response = await client.PostAsync(postUri, content);
            response.EnsureSuccessStatusCode();
        }
        public static ParameterGroupingModel ReadJson(string filename)
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
        public static string MapRegion(string region)
        {
            if (regionMapping.ContainsKey(region))
            {
                return regionMapping[region];
            }
            return region;
        }
        public static async Task<byte[]> ProcessFormFile(IFormFile formFile,
            ModelStateDictionary modelState, string[] permittedExtensions,
            long sizeLimit)
        {
            var fieldDisplayName = "";

            // Use reflection to obtain the display name for the model
            // property associated with this IFormFile. If a display
            // name isn't found, error messages simply won't show
            // a display name.
            MemberInfo property =
                typeof(FileUploadModel).GetProperty(
                    formFile.Name.Substring(formFile.Name.IndexOf(".", StringComparison.Ordinal) + 1));

            if (property != null)
            {
                if (property.GetCustomAttribute(typeof(DisplayAttribute)) is DisplayAttribute displayAttribute)
                {
                    fieldDisplayName = $"{displayAttribute.Name} ";
                }
            }

            // Don't trust the file name sent by the client. To display
            // the file name, HTML-encode the value.
            var trustedFileNameForDisplay = WebUtility.HtmlEncode(formFile.FileName);

            // Check the file length. This check doesn't catch files that only have 
            // a BOM as their content.
            if (formFile.Length == 0)
            {
                modelState.AddModelError(formFile.Name,
                    $"{fieldDisplayName}({trustedFileNameForDisplay}) is empty.");

                return Array.Empty<byte>();
            }

            if (formFile.Length > sizeLimit)
            {
                var megabyteSizeLimit = sizeLimit / 1048576;
                modelState.AddModelError(formFile.Name,
                    $"{fieldDisplayName}({trustedFileNameForDisplay}) exceeds " +
                    $"{megabyteSizeLimit:N1} MB.");

                return Array.Empty<byte>();
            }
            Regex rx = new Regex(@"^\w{0,4}-\w{4}-\w{0,7}-\w{0,15}\.tfvars$");
            if (!rx.IsMatch(formFile.FileName))
            {
                modelState.AddModelError(formFile.Name,
                    $"{fieldDisplayName}({trustedFileNameForDisplay}) is named incorrectly");
                
                return Array.Empty<byte>();
            }

            try
            {
                using (var memoryStream = new MemoryStream())
                {
                    await formFile.CopyToAsync(memoryStream);

                    // Check the content length in case the file's only
                    // content was a BOM and the content is actually
                    // empty after removing the BOM.
                    if (memoryStream.Length == 0)
                    {
                        modelState.AddModelError(formFile.Name,
                            $"{fieldDisplayName}({trustedFileNameForDisplay}) is empty.");
                    }

                    if (!IsValidFileExtension(formFile.FileName, memoryStream, permittedExtensions))
                    {
                        modelState.AddModelError(formFile.Name,
                            $"{fieldDisplayName}({trustedFileNameForDisplay}) file type isn't permitted.");
                    }
                    else
                    {
                        return memoryStream.ToArray();
                    }
                }
            }
            catch (Exception ex)
            {
                modelState.AddModelError(formFile.Name,
                    $"{fieldDisplayName}({trustedFileNameForDisplay}) upload failed. " +
                    $"Please contact the Help Desk for support. Error: {ex.HResult}");
            }

            return Array.Empty<byte>();
        }

        private static bool IsValidFileExtension(string fileName, Stream data, string[] permittedExtensions)
        {
            if (string.IsNullOrEmpty(fileName) || data == null || data.Length == 0)
            {
                return false;
            }

            var ext = Path.GetExtension(fileName).ToLowerInvariant();

            if (string.IsNullOrEmpty(ext) || !permittedExtensions.Contains(ext))
            {
                return false;
            }

            return true;
        }
        public static string TfvarToJson(string hclString)
        {
            StringReader stringReader = new StringReader(hclString);
            StringBuilder jsonString = new StringBuilder();
            jsonString.AppendLine("{");
            while (true)
            {
                string currLine = stringReader.ReadLine();
                if (currLine == null)
                {
                    jsonString.Remove(jsonString.Length - 3, 1);
                    jsonString.AppendLine("}");
                    break;
                }
                else if (currLine.StartsWith("#") || currLine == "")
                {
                    continue;
                }
                else if (currLine.StartsWith("}"))
                {
                    jsonString.Remove(jsonString.Length - 3, 1);
                    jsonString.AppendLine("},");
                }
                else
                {
                    int equalIndex = currLine.IndexOf("=");
                    if (equalIndex >= 0)
                    {
                        string key = currLine.Substring(0, equalIndex).Trim();
                        if (!key.StartsWith("\""))
                        {
                            key = "\"" + key + "\"";
                        }
                        string value = currLine.Substring(equalIndex + 1, currLine.Length - (equalIndex + 1)).Trim();
                        if (!value.EndsWith(",") && !value.EndsWith("{")) {
                            value += ",";
                        }
                        jsonString.AppendLine(key + ":" + value);
                    }
                }
            }
            return jsonString.ToString();
            
        }

    }
}
