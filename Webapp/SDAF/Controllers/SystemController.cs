// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using SDAFWebApp.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Net.Http.Headers;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using Azure.Identity;

namespace SDAFWebApp.Controllers
{
    public class SystemController : Controller
    {

        private readonly ITableStorageService<SystemEntity> _systemService;
        private readonly ITableStorageService<AppFile> _appFileService;
        private FormViewModel<SystemModel> systemView;
        private readonly IConfiguration _configuration;
        private readonly RestHelper restHelper;
        private readonly ILogger<SystemController> _logger;

        private ImageDropdown[] imagesOffered;
        private List<SelectListItem> imageOptions;
        private Dictionary<string, Image> imageMapping;
        private readonly string platform;
        private readonly string pipelineId;
        private readonly string branch;

        private static void LogDebug(string message)
        {
            System.Diagnostics.Debug.WriteLine($"[SystemController] {message}");
        }


        public SystemController(ITableStorageService<SystemEntity> systemService, ITableStorageService<AppFile> appFileService, IConfiguration configuration)
        {
            _systemService = systemService;
            _appFileService = appFileService;
            _configuration = configuration;

            platform = configuration["DEVOPS_PLATFORM"] ?? "ado";
            restHelper = new RestHelper(configuration, platform);
            systemView = SetViewData();

            imagesOffered = Helper.GetOfferedImages(_appFileService).Result;
            pipelineId = configuration["SYSTEM_PIPELINE_ID"];
            branch = configuration["SourceBranch"];

            InitializeImageOptionsAndMapping();

            LogDebug($"Platform: {platform}");
            LogDebug($"PipelineId: {pipelineId}");
            LogDebug($"Branch: {branch}");

        }
        private FormViewModel<SystemModel> SetViewData()
        {
            systemView = new FormViewModel<SystemModel>
            {
                SapObject = new SystemModel()
            };
            try
            {
                Grouping[] parameterArray = Helper.ReadJson<Grouping[]>("ParameterDetails/SystemDetails.json");

                systemView.ParameterGroupings = parameterArray;
            }
            catch
            {
                systemView.ParameterGroupings = Array.Empty<Grouping>();
            }

            return systemView;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            LogDebug("Index called");
            SapObjectIndexModel<SystemModel> systemIndex = new();

            try
            {
                List<SystemEntity> systemEntities = await _systemService.GetAllAsync();
                List<SystemModel> systems = systemEntities.FindAll(s => s.System != null).ConvertAll(s => JsonConvert.DeserializeObject<SystemModel>(s.System));
                systemIndex.SapObjects = systems;

                List<AppFile> appfiles = await _appFileService.GetAllAsync();
                systemIndex.AppFiles = appfiles.FindAll(file => !file.Id.EndsWith("INFRASTRUCTURE.tfvars") && file.Id != "VM-Images.json" && file.Id.IndexOf("_custom_") == -1);

                systemIndex.ImagesFile = await Helper.GetImagesFile(_appFileService);
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = "Error retrieving existing systems: " + e.Message;
            }

            return View(systemIndex);
        }

        [HttpGet]
        public async Task<SystemModel> GetById(string id, string partitionKey)
        {
            LogDebug($"GetById called. Id={id}, PartitionKey={partitionKey}");
            if (id == null || partitionKey == null) throw new ArgumentNullException();
            var systemEntity = await _systemService.GetByIdAsync(id, partitionKey);
            if (systemEntity == null || systemEntity.System == null) throw new KeyNotFoundException();
            SystemModel s = null;
            try
            {
                s = JsonConvert.DeserializeObject<SystemModel>(systemEntity.System);
            }
            catch (Exception e)
            {
                _logger?.LogWarning(e, "Failed to deserialize system {Id} in partition {PartitionKey}", Helper.SanitizeForLog(id), Helper.SanitizeForLog(partitionKey));
            }
            if (s == null) return null;
            try
            {
                AppFile file = await _appFileService.GetByIdAsync(id + "_custom_naming.json", partitionKey);
                s.name_override_file = id + "_custom_naming.json";
            }
            catch (Exception e)
            {
                _logger?.LogInformation(e, "No custom naming file found for system {Id}; using default naming", Helper.SanitizeForLog(id));
            }

            try
            {
                AppFile file = await _appFileService.GetByIdAsync(id + "_custom_sizes.json", partitionKey);
                s.custom_disk_sizes_filename = id + "_custom_sizes.json";
                s.database_size = "Custom";
            }
            catch (Exception e)
            {
                _logger?.LogInformation(e, "No custom sizes file found for system {Id}; using default sizing", Helper.SanitizeForLog(id));
            }

            return s;
        }

        [HttpGet]
        public async Task<SystemModel> GetDefault()
        {
            LogDebug("GetDefault called");
            SystemEntity defaultSystem = await _systemService.GetDefault();
            if (defaultSystem == null || defaultSystem.System == null) return null;
            return JsonConvert.DeserializeObject<SystemModel>(defaultSystem.System);
        }

        [HttpGet]
        public async Task<ActionResult> GetDefaultJson()
        {
            LogDebug("GetDefaultJson called");
            SystemEntity systemEntity = await _systemService.GetDefault();
            if (systemEntity == null) return NotFound();
            return Json(systemEntity.System);
        }

        public void InitializeImageOptionsAndMapping()
        {
            LogDebug("InitializeImageOptionsAndMapping called");
            imageMapping = [];
            imageOptions =
            [
                new SelectListItem()
            ];

            if (imagesOffered.Length > 0)
            {
                foreach (ImageDropdown imageDropdown in imagesOffered)
                {
                    if (!imageMapping.ContainsKey(imageDropdown.name))
                    {
                        imageMapping.Add(imageDropdown.name, imageDropdown.data);
                        imageOptions.Add(new SelectListItem(imageDropdown.name, imageDropdown.name));
                    }
                }
            }
        }

        [HttpGet]
        public ActionResult GetImage(string name)
        {
            LogDebug($"GetImage called. Name={name}");
            if (name != null && imageMapping.ContainsKey(name))
            {
                return Json(imageMapping[name]);
            }
            else
            {
                throw new Exception();
            }
        }

        [ActionName("Create")]
        public IActionResult Create()
        {
            LogDebug("Create (GET) called");
            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;
            return View(systemView);
        }

        [HttpPost]
        [ActionName("Create")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateAsync(SystemModel system)
        {
            LogDebug($"Create (POST) called. Id={system?.Id}");
            if (ModelState.IsValid)
            {
                try
                {
                    if (system.IsDefault)
                    {
                        await UnsetDefault(system.Id);
                    }
                    system.Id = Helper.GenerateId(system);
                    DateTime currentDateAndTime = DateTime.Now;
                    system.LastModified = currentDateAndTime.ToShortDateString();
                    system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                    SystemEntity systemEntity = new(system);
                    await _systemService.CreateAsync(systemEntity);
                    TempData["success"] = "Successfully created system " + system.Id;
                    return RedirectToAction("Index");
                }
                // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
                catch (Exception e)
                {
                    ModelState.AddModelError("SystemId", "Error creating system: " + e.Message);
                }
            }

            systemView.SapObject = system;

            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;

            return View(systemView);
        }

        [ActionName("Deploy")]
        public async Task<IActionResult> DeployAsync(string id, string partitionKey)
        {
            LogDebug($"Deploy (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);
                systemView.SapObject = system;

                List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                ViewBag.Environments = environments;

                return View(systemView);
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = e.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [ActionName("Deploy")]
        public async Task<RedirectToActionResult> DeployConfirmedAsync(string id, string partitionKey, Templateparameters parameters)
        {
            LogDebug($"Deploy (POST) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);

                AppFile file = null;
                try
                {
                    file = await _appFileService.GetByIdAsync(id + "_custom_naming.json", partitionKey);
                    system.name_override_file = id + "_custom_naming.json";
                    using var stream = new MemoryStream(file.Content);

                    string thisContent = System.Text.Encoding.UTF8.GetString(stream.ToArray());
                    string pathForNaming = $"/SYSTEM/{id}/{id}_custom_naming.json";

                    await restHelper.UpdateRepo(pathForNaming, thisContent);
                }
                catch (Exception e)
                {
                    _logger?.LogWarning(e, "Failed to save custom naming file for system {Id}; continuing with default naming", Helper.SanitizeForLog(id));
                }

                try
                {
                    file = await _appFileService.GetByIdAsync(id + "_custom_sizes.json", partitionKey);
                    using var stream = new MemoryStream(file.Content);

                    system.custom_disk_sizes_filename = id + "_custom_sizes.json";
                    system.database_size = "Custom";

                    string thisContent = System.Text.Encoding.UTF8.GetString(stream.ToArray());
                    string pathForNaming = $"/SYSTEM/{id}/{id}_custom_sizes.json";

                    await restHelper.UpdateRepo(pathForNaming, thisContent);
                }
                catch (Exception e)
                {
                    _logger?.LogWarning(e, "Failed to save custom sizes file for system {Id}; continuing with default sizing", Helper.SanitizeForLog(id));
                }

                string path = $"/SYSTEM/{id}/{id}.tfvars";

                if (!string.IsNullOrEmpty(system.subscription))
                {
                    system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                }

                if (string.IsNullOrEmpty(system.environment) && !string.IsNullOrEmpty(system.workload_zone))
                {
                    system.environment = system.workload_zone.Split('-')[0];
                }
                if (string.IsNullOrEmpty(system.network_logical_name) && !string.IsNullOrEmpty(system.workload_zone))
                {
                    system.network_logical_name = system.workload_zone.Split('-')[2];
                }

                string content = Helper.ConvertToTerraform(system);

                await restHelper.UpdateRepo(path, content);

                switch (platform.ToLower())
                {
                    case "ado":
                        {

                            parameters.sap_system = id;
                            PipelineRequestBody requestBody = new()
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
                                },
                                templateParameters = parameters
                            };

                            await restHelper.TriggerPipeline(pipelineId, requestBody);

                            TempData["success"] = "Successfully triggered system deployment pipeline for " + id;
                            break;
                        }
                    case "github":
                        {
                            // Trigger with
                            var inputs = new Dictionary<string, object>
                            {
                                { "workload_zone_name", parameters.environment },
                                { "sap_system_identifier", system.sid }
                            };
                            await restHelper.TriggerGitHubWorkflow("05-sap-system-deployment.yml", "main", inputs);
                            TempData["success"] = "Successfully triggered system deployment action for " + id;
                            break;


                        }
                }

            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = "Error deploying system " + id + ": " + e.Message;
            }
            return RedirectToAction("Index");
        }

        [ActionName("Install")]
        public async Task<IActionResult> InstallAsync(string id, string partitionKey)
        {
            LogDebug($"Install (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);
                systemView.SapObject = system;

                List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                ViewBag.Environments = environments;

                return View(systemView);
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = e.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [ActionName("Install")]
        public async Task<IActionResult> InstallConfirmedAsync(string id, string partitionKey, Templateparameters parameters)
        {
            LogDebug($"Install (POST) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);

                switch (platform.ToLower())
                {
                    case "ado":
                        {

                            string pipelineId = _configuration["SAP_INSTALL_PIPELINE_ID"];
                            string branch = _configuration["SourceBranch"];
                            PipelineRequestBody requestBody = new()
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
                                },
                                templateParameters = parameters
                            };

                            await restHelper.TriggerPipeline(pipelineId, requestBody);
                            TempData["success"] = "Successfully triggered SAP installation pipeline for " + id;
                            break;
                        }
                    case "github":
                        {
                            // Trigger with
                            var inputs = new Dictionary<string, object>
                            {
                                { "workload_zone_name", parameters.environment },
                                { "sap_system_identifier", system.sid },
                                { "bom_override_name", parameters.bom_base_name },
                                { "base_os_configuration", parameters.base_os_configuration },
                                { "sap_os_configuration", parameters.sap_os_configuration },
                                { "bom_processing", parameters.bom_processing },
                                { "scs_installation", parameters.scs_installation },
                                { "database_install", parameters.database_install },
                                { "db_load", parameters.db_load },
                                { "high_availability_configuration", parameters.high_availability_configuration },
                                { "pas_installation", parameters.pas_installation },
                                { "application_server_installation", parameters.application_server_installation },
                                { "webdispatcher_installation", parameters.webdispatcher_installation }
                            };
                            await restHelper.TriggerGitHubWorkflow("07-configuration-installation.yml", "main", inputs);
                            TempData["success"] = "Successfully triggered system installation action for " + id;
                            break;
                        }
                }

            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = "Error triggering SAP installation pipeline for system " + id + ": " + e.Message;
            }
            return RedirectToAction("Index");
        }

        [ActionName("Remove")]
        public async Task<IActionResult> RemoveAsync(string id, string partitionKey)
        {
            LogDebug($"Remove (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);
                systemView.SapObject = system;

                List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                ViewBag.Environments = environments;


                return View(systemView);
            }
            catch (Exception e)
            {
                TempData["error"] = e.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [ActionName("Remove")]
        public async Task<RedirectToActionResult> RemoveConfirmedAsync(
            string id,
            string partitionKey,
            [Bind("cleanup_sap,sap_system,cleanup_zone,workload_zone,use_deployer")] RemovalTemplateParameters parameters)
        {
            LogDebug($"Remove (POST) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);

                string path = $"/LANDSCAPE/{id}/{id}.tfvars";
                parameters.cleanup_zone = true;
                parameters.cleanup_sap = false;


                if (!string.IsNullOrEmpty(system.subscription))
                {
                    system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                }

                if (string.IsNullOrEmpty(system.environment) && !string.IsNullOrEmpty(system.workload_zone))
                {
                    system.environment = system.workload_zone.Split('-')[0];
                }


                switch (platform.ToLower())
                {
                    case "ado":
                        {
                            string pipelineId = _configuration["REMOVAL_PIPELINE_ID"];
                            string branch = _configuration["SourceBranch"];

                            parameters.workload_zone = id.Replace("-INFRASTRUCTURE", "");
                            parameters.sap_system = id;
                            parameters.cleanup_sap = true;
                            parameters.cleanup_zone = false;

                            PipelineRequestBody requestBody = new()
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
                                },
                                templateParameters = new Dictionary<string, object>
                            {
                                { "workload_zone", system.workload_zone },
                                { "cleanup_sap", true },
                                { "cleanup_zone", false },
                                { "sap_system", id }
                            }
                            };

                            LogDebug($"Calling removal pipeline {pipelineId} for {id}");

                            await restHelper.TriggerPipeline(pipelineId, requestBody);

                            TempData["success"] = "Successfully triggered workload zone removal pipeline for " + id;
                            break;
                        }
                    case "github":
                        {
                            // Trigger with inputs
                            var inputs = new Dictionary<string, object>
                            {
                                { "workload_zone_name", system.workload_zone },
                                { "cleanup_sap", true },
                                { "cleanup_workload_zone", false },
                                { "sap_system_identifier", id }

                            };
                            await restHelper.TriggerGitHubWorkflow("10-remover-terraform.yml", "main", inputs);
                            TempData["success"] = "Successfully system removal action for " + id;
                            break;
                        }
                }

            }
            catch (Exception e)
            {
                TempData["error"] = "Error removing workload zone " + id + ": " + e.Message;
            }
            return RedirectToAction("Index");
        }


        [ActionName("Delete")]
        public async Task<IActionResult> DeleteAsync(string id, string partitionKey)
        {
            LogDebug($"Delete (GET) called. Id={id}, PartitionKey={partitionKey}");
            if (id == null)
            {
                return BadRequest();
            }

            SystemModel system = await GetById(id, partitionKey);
            systemView.SapObject = system;
            if (system == null)
            {
                return NotFound();
            }

            return View(systemView);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmedAsync(string id, string partitionKey)
        {
            LogDebug($"Delete (POST) called. Id={id}, PartitionKey={partitionKey}");
            await _systemService.DeleteAsync(id, partitionKey);
            TempData["success"] = "Successfully deleted system " + id;
            return RedirectToAction("Index");
        }

        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id, string partitionKey)
        {
            LogDebug($"Edit (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);
                if (!string.IsNullOrEmpty(system.subscription))
                {
                    system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                }

                if (string.IsNullOrEmpty(system.environment) && !string.IsNullOrEmpty(system.workload_zone))
                {
                    system.environment = system.workload_zone.Split('-')[0];
                }
                if (string.IsNullOrEmpty(system.network_logical_name) && !string.IsNullOrEmpty(system.workload_zone))
                {
                    system.network_logical_name = system.workload_zone.Split('-')[2];
                }

                systemView.SapObject = system;

                ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
                ViewBag.ImageOptions = imageOptions;

                return View(systemView);
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = e.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditAsync(SystemModel system)
        {
            LogDebug($"Edit (POST) called. Id={system?.Id}");
            if (ModelState.IsValid)
            {
                try
                {
                    string newId = Helper.GenerateId(system);
                    system.Id ??= newId;
                    if (newId != system.Id)
                    {
                        if (String.IsNullOrEmpty(system.Description))
                        {
                            if (system.database_high_availability == true || system.scs_high_availability == true)
                            {
                                system.Description = system.database_platform + " high availability system on " + system.scs_server_image.publisher + " " + system.scs_server_image.offer + " " + system.scs_server_image.sku;
                            }
                            else
                            {
                                system.Description = system.database_platform + " distributed system on " + system.scs_server_image.publisher + " " + system.scs_server_image.offer + " " + system.scs_server_image.sku;
                            }
                        }
                        if (!string.IsNullOrEmpty(system.subscription))
                        {
                            system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                        }

                        if (string.IsNullOrEmpty(system.environment) && !string.IsNullOrEmpty(system.workload_zone))
                        {
                            system.environment = system.workload_zone.Split('-')[0];
                        }
                        if (string.IsNullOrEmpty(system.network_logical_name) && !string.IsNullOrEmpty(system.workload_zone))
                        {
                            system.network_logical_name = system.workload_zone.Split('-')[2];
                        }

                        await SubmitNewAsync(system);
                        string id = system.Id;
                        string path = $"/SYSTEM/{id}/{id}.tfvars";
                        string content = Helper.ConvertToTerraform(system);
                        byte[] bytes = Encoding.UTF8.GetBytes(content);

                        AppFile file = new()
                        {
                            Id = WebUtility.HtmlEncode(path),
                            Content = bytes,
                            UntrustedName = path,
                            Size = bytes.Length,
                            UploadDT = DateTime.UtcNow
                        };

                        await _systemService.CreateTFVarsAsync(file);
                        return RedirectToAction("Edit", "System", new { @id = system.Id, @partitionKey = system.Id });  //RedirectToAction("Index");


                    }
                    else
                    {
                        if (system.IsDefault)
                        {
                            await UnsetDefault(system.Id);
                        }
                        if (String.IsNullOrEmpty(system.Description))
                        {
                            if (system.database_high_availability == true || system.scs_high_availability == true)
                            {
                                system.Description = system.database_platform + " high availability system on " + system.scs_server_image.publisher + " " + system.scs_server_image.offer + " " + system.scs_server_image.sku;
                            }
                            else
                            {
                                system.Description = system.database_platform + " distributed system on " + system.scs_server_image.publisher + " " + system.scs_server_image.offer + " " + system.scs_server_image.sku;
                            }
                        }
                        if (!string.IsNullOrEmpty(system.subscription))
                        {
                            system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                        }

                        if (string.IsNullOrEmpty(system.environment) && !string.IsNullOrEmpty(system.workload_zone))
                        {
                            system.environment = system.workload_zone.Split('-')[0];
                        }
                        if (string.IsNullOrEmpty(system.network_logical_name) && !string.IsNullOrEmpty(system.workload_zone))
                        {
                            system.network_logical_name = system.workload_zone.Split('-')[2];
                        }

                        DateTime currentDateAndTime = DateTime.Now;
                        system.LastModified = currentDateAndTime.ToShortDateString();
                        await _systemService.UpdateAsync(new SystemEntity(system));

                        TempData["success"] = "Successfully updated system " + system.Id;
                        string id = system.Id;
                        string path = $"/SYSTEM/{id}/{id}.tfvars";
                        string content = Helper.ConvertToTerraform(system);
                        byte[] bytes = Encoding.UTF8.GetBytes(content);

                        AppFile file = new()
                        {
                            Id = WebUtility.HtmlEncode(path),
                            Content = bytes,
                            UntrustedName = path,
                            Size = bytes.Length,
                            UploadDT = DateTime.UtcNow
                        };

                        await _systemService.CreateTFVarsAsync(file);
                        return RedirectToAction("Edit", "System", new { @id = system.Id, @partitionKey = system.Id });  //RedirectToAction("Index");
                    }
                }
                // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
                catch (Exception e)
                {
                    ModelState.AddModelError("SystemId", "Error editing system: " + e.Message);
                }
            }

            systemView.SapObject = system;

            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;

            return View(systemView);
        }

        [HttpPost]
        [ActionName("SubmitNew")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitNewAsync(SystemModel system)
        {
            LogDebug($"SubmitNew (POST) called. Id={system?.Id}");
            if (ModelState.IsValid)
            {
                try
                {
                    if (system.IsDefault)
                    {
                        await UnsetDefault(system.Id);
                    }
                    system.Id = Helper.GenerateId(system);
                    DateTime currentDateAndTime = DateTime.Now;
                    system.LastModified = currentDateAndTime.ToShortDateString();
                    if (!string.IsNullOrEmpty(system.subscription))
                    {
                        system.subscription_id = system.subscription.Replace("/subscriptions/", "");
                    }

                    if (string.IsNullOrEmpty(system.environment) && !string.IsNullOrEmpty(system.workload_zone))
                    {
                        system.environment = system.workload_zone.Split('-')[0];
                    }
                    if (string.IsNullOrEmpty(system.network_logical_name) && !string.IsNullOrEmpty(system.workload_zone))
                    {
                        system.network_logical_name = system.workload_zone.Split('-')[2];
                    }

                    await _systemService.CreateAsync(new SystemEntity(system));
                    TempData["success"] = "Successfully created system " + system.Id;
                    return RedirectToAction("Index");
                }
                // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
                catch (Exception e)
                {
                    ModelState.AddModelError("SystemId", "Error creating system: " + e.Message);
                }
            }

            systemView.SapObject = system;

            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;

            return View("Edit", systemView);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id, string partitionKey)
        {
            LogDebug($"Details called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = await GetById(id, partitionKey);
                systemView.SapObject = system;
                return View(systemView);
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = e.Message;
                return RedirectToAction("Index");
            }
        }

        [ActionName("Download")]
        public ActionResult DownloadFile(string id, string partitionKey)
        {
            LogDebug($"Download called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                SystemModel system = GetById(id, partitionKey).Result;

                string path = $"{id}.tfvars";
                string content = Helper.ConvertToTerraform(system);

                // FileStreamResult takes ownership of the stream and disposes it after writing the response.
                var stream = new MemoryStream(Encoding.UTF8.GetBytes(content));
                return new FileStreamResult(stream, new MediaTypeHeaderValue("text/plain"))
                {
                    FileDownloadName = path
                };
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = "Something went wrong downloading file " + id + ": " + e.Message;
                return RedirectToAction("Index");
            }
        }

        [ActionName("MakeDefault")]
        public async Task<IActionResult> MakeDefault(string id, string partitionKey)
        {
            LogDebug($"MakeDefault called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                // Unset the existing default
                await UnsetDefault(id);

                // Update current system as default
                SystemModel system = await GetById(id, partitionKey);
                system.IsDefault = true;
                SystemEntity systemEntity = new(system);
                await _systemService.UpdateAsync(systemEntity);
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                ModelState.AddModelError("SystemId", "Error setting default for system: " + e.Message);
            }
            return RedirectToAction("Index");
        }

        public async Task UnsetDefault(string id)
        {
            LogDebug($"UnsetDefault called. Id={id}");
            try
            {
                SystemModel existingDefault = await GetDefault();
                if (existingDefault != null && existingDefault.Id != id)
                {
                    existingDefault.IsDefault = false;
                    await _systemService.UpdateAsync(new SystemEntity(existingDefault));
                    Console.WriteLine("Unset existing default " + existingDefault.Id);
                }
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                throw new Exception("Error unsetting the current default object: " + e.Message);
            }
        }

    }
}
