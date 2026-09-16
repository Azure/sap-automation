// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Microsoft.Net.Http.Headers;
using Newtonsoft.Json;
using SDAFWebApp.Models;
using SDAFWebApp.Services;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace SDAFWebApp.Controllers
{
    public class LandscapeController : Controller
    {

        private readonly ITableStorageService<LandscapeEntity> _landscapeService;
        private readonly ITableStorageService<AppFile> _appFileService;
        private FormViewModel<LandscapeModel> landscapeView;
        private readonly IConfiguration _configuration;
        private readonly RestHelper restHelper;

        private readonly ImageDropdown[] imagesOffered;
        private List<SelectListItem> imageOptions;
        private Dictionary<string, Image> imageMapping;
        private readonly string sdafControlPlaneEnvironment;
        private readonly string sdafControlPlaneLocation;
        private readonly string sdafControlPlaneName;
        private readonly string platform;
        private readonly string pipelineId;
        private readonly string branch;

        private static void LogDebug(string message)
        {
            System.Diagnostics.Debug.WriteLine($"[LandscapeController] {message}");
        }



        public LandscapeController(ITableStorageService<LandscapeEntity> landscapeService, ITableStorageService<AppFile> appFileService, IConfiguration configuration)
        {
            _landscapeService = landscapeService;
            _appFileService = appFileService;
            _configuration = configuration;
            platform = configuration["DEVOPS_PLATFORM"] ?? "ado";
            restHelper = new RestHelper(configuration, platform);
            landscapeView = SetViewData();
            imagesOffered = Helper.GetOfferedImages(_appFileService).Result;
            InitializeImageOptionsAndMapping();
            sdafControlPlaneEnvironment = configuration["CONTROLPLANE_ENV"];
            sdafControlPlaneLocation = configuration["CONTROLPLANE_LOC"];
            sdafControlPlaneName = configuration["CONTROL_PLANE_NAME"];
            pipelineId = configuration["WORKLOADZONE_PIPELINE_ID"];
            branch = configuration["SourceBranch"];

            LogDebug($"Platform: {platform}");
            LogDebug($"PipelineId: {pipelineId}");
            LogDebug($"Branch: {branch}");
            LogDebug($"ControlPlaneEnvironment: {sdafControlPlaneEnvironment}");
            LogDebug($"ControlPlaneLocation: {sdafControlPlaneLocation}");
            LogDebug($"ControlPlaneName: {sdafControlPlaneName}");


        }
        private FormViewModel<LandscapeModel> SetViewData()
        {
            landscapeView = new FormViewModel<LandscapeModel>
            {
                SapObject = new LandscapeModel()
            };
            try
            {
                Grouping[] parameterArray = Helper.ReadJson<Grouping[]>("ParameterDetails/LandscapeDetails.json");

                landscapeView.ParameterGroupings = parameterArray;
            }
            catch
            {
                landscapeView.ParameterGroupings = Array.Empty<Grouping>();
            }

            return landscapeView;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            LogDebug("Index called");
            SapObjectIndexModel<LandscapeModel> landscapeIndex = new();

            try
            {
                List<LandscapeEntity> landscapeEntities = await _landscapeService.GetAllAsync();
                List<LandscapeModel> landscapes = landscapeEntities
                    .FindAll(l => l.Landscape != null)
                    .ConvertAll(l => NormalizeLoadedLandscape(JsonConvert.DeserializeObject<LandscapeModel>(l.Landscape)));
                landscapeIndex.SapObjects = landscapes;

                List<AppFile> appfiles = await _appFileService.GetAllAsync();
                landscapeIndex.AppFiles = appfiles.FindAll(file => file.Id.EndsWith("INFRASTRUCTURE.tfvars"));
            }
            catch (Exception e)
            {
                TempData["error"] = "Error retrieving existing workload zones: " + e.Message;
            }

            return View(landscapeIndex);
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
        public async Task<ActionResult> GetWorkloadZones()
        {
            LogDebug("GetWorkloadZones called");
            List<SelectListItem> options =
      [
                new SelectListItem { Text = "", Value = "" }
            ];
            try
            {

                if (platform == "ado")
                {
                    List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                    foreach (SelectListItem zone in environments)
                    {
                        options.Add(zone);
                    }
                }
                else
                {
                    List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                    foreach (SelectListItem zone in environments)
                    {
                        options.Add(zone);
                    }
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }

        [HttpGet]
        public async Task<LandscapeModel> GetById(string id, string partitionKey)
        {
            LogDebug($"GetById called. Id={id}, PartitionKey={partitionKey}");
            if (id == null) throw new ArgumentNullException(nameof(id), "Parameter 'id' cannot be null.");
            if (partitionKey == null) throw new ArgumentNullException(nameof(partitionKey), "Parameter 'partitionKey' cannot be null.");
            var landscapeEntity = await _landscapeService.GetByIdAsync(id, partitionKey);
            if (landscapeEntity == null || landscapeEntity.Landscape == null) throw new KeyNotFoundException();
            return NormalizeLoadedLandscape(JsonConvert.DeserializeObject<LandscapeModel>(landscapeEntity.Landscape));
        }

        // Format correctly for javascript consumption
        [HttpGet]
        public async Task<ActionResult> GetByIdJson(string id)
        {
            LogDebug($"GetByIdJson called. Id={id}");
            // PartitionKey is the landscape's full Id (see LandscapeEntity), not the environment prefix.
            LandscapeEntity landscape = await _landscapeService.GetByIdAsync(id, id);
            if (landscape == null || landscape.Landscape == null) return NotFound();
            return Json(landscape.Landscape);
        }

        [HttpGet]
        public async Task<LandscapeModel> GetDefault()
        {
            LogDebug("GetDefault called");
            LandscapeEntity defaultLandscape = await _landscapeService.GetDefault();
            if (defaultLandscape == null || defaultLandscape.Landscape == null) return null;
            return NormalizeLoadedLandscape(JsonConvert.DeserializeObject<LandscapeModel>(defaultLandscape.Landscape));
        }

        private static LandscapeModel NormalizeLoadedLandscape(LandscapeModel landscape)
        {
            if (landscape != null)
            {
                landscape.IsValid();
            }

            return landscape;
        }

        [HttpGet]
        public ActionResult GetDefaultJson()
        {
            LogDebug("GetDefaultJson called");
            LandscapeEntity landscapeEntity = _landscapeService.GetDefault().Result;
            if (landscapeEntity == null) return NotFound();
            return Json(landscapeEntity.Landscape);
        }

        [ActionName("Create")]
        public IActionResult Create()
        {
            LogDebug("Create (GET) called");
            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;
            return View(landscapeView);
        }

        [HttpPost]
        [ActionName("Create")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateAsync(LandscapeModel landscape)
        {
            LogDebug($"Create (POST) called. InputId={landscape?.Id}");
            if (ModelState.IsValid || landscape.IsDefault)
            {
                try
                {
                    if (landscape.IsDefault)
                    {
                        await UnsetDefault(landscape.Id);
                    }
                    landscape.Id = Helper.GenerateId(landscape);
                    DateTime currentDateAndTime = DateTime.Now;
                    landscape.LastModified = currentDateAndTime.ToShortDateString();
                    if (!string.IsNullOrEmpty(landscape.subscription))
                    {
                        landscape.subscription_id = landscape.subscription.Replace("/subscriptions/", "");
                    }

                    if (string.IsNullOrEmpty(landscape.environment) && !string.IsNullOrEmpty(landscape.workload_zone))
                    {
                        landscape.environment = landscape.workload_zone.Split('-')[0];
                    }
                    if (string.IsNullOrEmpty(landscape.network_logical_name) && !string.IsNullOrEmpty(landscape.workload_zone))
                    {
                        landscape.network_logical_name = landscape.workload_zone.Split('-')[2];
                    }

                    await _landscapeService.CreateAsync(new LandscapeEntity(landscape));
                    TempData["success"] = "Successfully created workload zone " + landscape.Id;
                    LogDebug($"Successfully created workload zone {landscape.Id}");

                    string id = landscape.Id;
                    string path = $"/LANDSCAPE/{id}/{id}.tfvars";
                    string content = Helper.ConvertToTerraform(landscape);

                    return RedirectToAction("Index");
                }
                catch (Exception e)
                {
                    ModelState.AddModelError("LandscapeId", "Error creating workload zone: " + e.Message);
                }
            }

            landscapeView.SapObject = landscape;
            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;

            return View(landscapeView);
        }

        [ActionName("Deploy")]
        public async Task<IActionResult> DeployAsync(string id, string partitionKey)
        {
            LogDebug($"Deploy (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                LandscapeModel landscape = await GetById(id, partitionKey);
                landscape.controlPlaneEnvironment = sdafControlPlaneEnvironment;
                landscape.controlPlaneLocation = sdafControlPlaneLocation;
                landscape.controlPlaneName = sdafControlPlaneName;
                landscapeView.SapObject = landscape;

                List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                ViewBag.Environments = environments;


                return View(landscapeView);
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
                LandscapeModel landscape = await GetById(id, partitionKey);

                string path = $"/LANDSCAPE/{id}/{id}.tfvars";


                if (!string.IsNullOrEmpty(landscape.subscription))
                {
                    landscape.subscription_id = landscape.subscription.Replace("/subscriptions/", "");
                }

                if (string.IsNullOrEmpty(landscape.environment) && !string.IsNullOrEmpty(landscape.workload_zone))
                {
                    landscape.environment = landscape.workload_zone.Split('-')[0];
                }

                string content = Helper.ConvertToTerraform(landscape);

                await restHelper.UpdateRepo(path, content);

                switch (platform.ToLower())
                {
                    case "ado":
                        {

                        parameters.workload_zone = id;
                        parameters.environment = null;
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

                            LogDebug($"Calling pipeline {pipelineId} for {id}");
                            await restHelper.TriggerPipeline(pipelineId, requestBody);

                        TempData["success"] = "Successfully triggered workload zone deployment pipeline for " + id;
                        break;
                        }
                    case "github":
                    {
                            // Trigger with inputs
                            var inputs = new Dictionary<string, object>
                            {
                                { "workload_zone_name", id.Replace("-INFRASTRUCTURE", "") },
                                { "control_plane_name", sdafControlPlaneName }
                            };
                            await restHelper.TriggerGitHubWorkflow("03-deploy-sap-workload-zone.yml", "main", inputs);
                            TempData["success"] = "Successfully triggered workload zone deployment action for " + id;
                            break;
                        }
                }

            }
            catch (Exception e)
            {
                TempData["error"] = "Error deploying workload zone " + id + ": " + e.Message;
            }
            return RedirectToAction("Index");
        }

        [ActionName("Remove")]
        public async Task<IActionResult> RemoveAsync(string id, string partitionKey)
        {
            LogDebug($"Remove (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                LandscapeModel landscape = await GetById(id, partitionKey);
                landscape.controlPlaneEnvironment = sdafControlPlaneEnvironment;
                landscape.controlPlaneLocation = sdafControlPlaneLocation;
                landscape.controlPlaneName = sdafControlPlaneName;
                landscapeView.SapObject = landscape;

                List<SelectListItem> environments = restHelper.GetEnvironmentsList().Result;
                ViewBag.Environments = environments;


                return View(landscapeView);
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
                LandscapeModel landscape = await GetById(id, partitionKey);

                string path = $"/LANDSCAPE/{id}/{id}.tfvars";
                parameters.cleanup_zone = true;
                parameters.cleanup_sap = false;


                if (!string.IsNullOrEmpty(landscape.subscription))
                {
                    landscape.subscription_id = landscape.subscription.Replace("/subscriptions/", "");
                }

                if (string.IsNullOrEmpty(landscape.environment) && !string.IsNullOrEmpty(landscape.workload_zone))
                {
                    landscape.environment = landscape.workload_zone.Split('-')[0];
                }


                switch (platform.ToLower())
                {
                    case "ado":
                        {
                        string pipelineId = _configuration["REMOVAL_PIPELINE_ID"];
                        string branch = _configuration["SourceBranch"];

                        parameters.workload_zone = id.Replace("-INFRASTRUCTURE", "");
                        parameters.sap_system = "";
                        parameters.cleanup_sap = false;
                        parameters.cleanup_zone = true;

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
                                { "workload_zone", id.Replace("-INFRASTRUCTURE", "") },
                                { "cleanup_sap", false },
                                { "cleanup_zone", true },
                                { "sap_system", "N/A" }
                            }
                        };

                        LogDebug($"Calling pipeline {pipelineId} for {id}");

                        await restHelper.TriggerPipeline(pipelineId, requestBody);

                        TempData["success"] = "Successfully triggered workload zone removal pipeline for " + id;
                        break;
                        }
                    case "github":
                    {
                            // Trigger with inputs
                            var inputs = new Dictionary<string, object>
                            {
                                { "workload_zone_name", "N/A" },
                                { "cleanup_sap", true },
                                { "cleanup_workload_zone", false },
                                { "sap_system_identifier", id }

                            };
                            await restHelper.TriggerGitHubWorkflow("10-remover-terraform.yml", "main", inputs);
                            TempData["success"] = "Successfully triggered workload zone removal action for " + id;
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

            LandscapeModel landscape = await GetById(id, partitionKey);
            landscapeView.SapObject = landscape;
            if (landscape == null)
            {
                return NotFound();
            }

            return View(landscapeView);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmedAsync(string id, string partitionKey)
        {
            LogDebug($"Delete (POST) called. Id={id}, PartitionKey={partitionKey}");
            await _landscapeService.DeleteAsync(id, partitionKey);
            TempData["success"] = "Successfully deleted workload zone " + id;
            return RedirectToAction("Index");
        }

        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id, string partitionKey)
        {
            LogDebug($"Edit (GET) called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                ActionResult<LandscapeModel> result = await GetById(id, partitionKey);
                LandscapeModel landscape = result.Value;
                if (!string.IsNullOrEmpty(landscape.subscription))
                {
                    landscape.subscription_id = landscape.subscription.Replace("/subscriptions/", "");
                }

                if (string.IsNullOrEmpty(landscape.environment) && !string.IsNullOrEmpty(landscape.workload_zone))
                {
                    landscape.environment = landscape.workload_zone.Split('-')[0];
                }
                if (string.IsNullOrEmpty(landscape.network_logical_name) && !string.IsNullOrEmpty(landscape.workload_zone))
                {
                    landscape.network_logical_name = landscape.workload_zone.Split('-')[2];
                }

                landscapeView.SapObject = landscape;
                ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
                ViewBag.ImageOptions = imageOptions;
                return View(landscapeView);
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
        public async Task<IActionResult> EditAsync(LandscapeModel landscape)
        {
            LogDebug($"Edit (POST) called. Id={landscape?.Id}");
            if (ModelState.IsValid)
            {
                try
                {
                    string newId = Helper.GenerateId(landscape);
                    landscape.Id ??= newId;
                    if (newId != landscape.Id)
                    {
                        landscape.Id = newId;
                        await SubmitNewAsync(landscape);
                        string id = landscape.Id;
                        string path = $"/LANDSCAPE/{id}/{id}.tfvars";
                        string content = Helper.ConvertToTerraform(landscape);
                        byte[] bytes = Encoding.UTF8.GetBytes(content);

                        AppFile file = new()
                        {
                            Id = WebUtility.HtmlEncode(path),
                            Content = bytes,
                            UntrustedName = path,
                            Size = bytes.Length,
                            UploadDT = DateTime.UtcNow
                        };

                        await _landscapeService.CreateTFVarsAsync(file);

                        return RedirectToAction("Edit", "Landscape", new { @id = landscape.Id, @partitionKey = landscape.Id });  //RedirectToAction("Index");
                    }
                    else
                    {
                        if (landscape.IsDefault)
                        {
                            await UnsetDefault(landscape.Id);
                        }
                        DateTime currentDateAndTime = DateTime.Now;
                        landscape.LastModified = currentDateAndTime.ToShortDateString();
                        if (string.IsNullOrEmpty(landscape.environment) && !string.IsNullOrEmpty(landscape.workload_zone))
                        {
                            landscape.environment = landscape.workload_zone.Split('-')[0];
                        }
                        if (string.IsNullOrEmpty(landscape.network_logical_name) && !string.IsNullOrEmpty(landscape.workload_zone))
                        {
                            landscape.network_logical_name = landscape.workload_zone.Split('-')[2];
                        }
                        if (!string.IsNullOrEmpty(landscape.subscription))
                        {
                            landscape.subscription_id = landscape.subscription.Replace("/subscriptions/", "");
                        }

                       await _landscapeService.UpdateAsync(new LandscapeEntity(landscape));
                        TempData["success"] = "Successfully updated workload zone " + landscape.Id;

                        string id = landscape.Id;
                        string path = $"/LANDSCAPE/{id}/{id}.tfvars";
                        string content = Helper.ConvertToTerraform(landscape);
                        byte[] bytes = Encoding.UTF8.GetBytes(content);

                        AppFile file = new()
                        {
                            Id = WebUtility.HtmlEncode(path),
                            Content = bytes,
                            UntrustedName = path,
                            Size = bytes.Length,
                            UploadDT = DateTime.UtcNow
                        };

                        await _landscapeService.CreateTFVarsAsync(file);

                        return RedirectToAction("Edit", "Landscape", new { @id = landscape.Id, @partitionKey = landscape.Id });  //RedirectToAction("Index");
                    }
                }
                catch (Exception e)
                {
                    ModelState.AddModelError("LandscapeId", "Error editing workload zone: " + e.Message);
                }
            }

            landscapeView.SapObject = landscape;
            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;

            return View(landscapeView);
        }

        [HttpPost]
        [ActionName("SubmitNew")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitNewAsync(LandscapeModel landscape)
        {
            LogDebug($"SubmitNew (POST) called. Id={landscape?.Id}");
            if (ModelState.IsValid)
            {
                try
                {
                    if (landscape.IsDefault)
                    {
                        await UnsetDefault(landscape.Id);
                    }
                    landscape.Id = Helper.GenerateId(landscape);
                    DateTime currentDateAndTime = DateTime.Now;
                    landscape.LastModified = currentDateAndTime.ToShortDateString();

                    await _landscapeService.CreateAsync(new LandscapeEntity(landscape));
                    TempData["success"] = "Successfully created workload zone " + landscape.Id;
                    string id = landscape.Id;
                    string content = Helper.ConvertToTerraform(landscape);

                    byte[] bytes = Encoding.UTF8.GetBytes(content);

                    AppFile file = new()
                    {
                        Id = WebUtility.HtmlEncode(id),
                        Content = bytes,
                        UntrustedName = id,
                        Size = bytes.Length,
                        UploadDT = DateTime.UtcNow
                    };

                    await _landscapeService.CreateTFVarsAsync(file);


                    return RedirectToAction("Index");
                }
                // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
                catch (Exception e)
                {
                    ModelState.AddModelError("LandscapeId", "Error creating workload zone: " + e.Message);
                }
            }

            landscapeView.SapObject = landscape;
            ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
            ViewBag.ImageOptions = imageOptions;

            return View("Edit", landscapeView);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id, string partitionKey)
        {
            LogDebug($"Details called. Id={id}, PartitionKey={partitionKey}");
            try
            {
                ActionResult<LandscapeModel> result = await GetById(id, partitionKey);
                LandscapeModel landscape = result.Value;
                landscapeView.SapObject = landscape;
                return View(landscapeView);
            }
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
                LandscapeModel landscape = GetById(id, partitionKey).Result;

                string path = $"{id}.tfvars";
                string content = Helper.ConvertToTerraform(landscape);

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
                await UnsetDefault(id);

                ActionResult<LandscapeModel> result = await GetById(id, partitionKey);
                LandscapeModel landscape = result.Value;

                landscape.IsDefault = true;
                LandscapeEntity landscapeEntity = new(landscape);
                await _landscapeService.UpdateAsync(landscapeEntity);
                TempData["success"] = id + " is now the default workload zone";
            }
            // Intentional top-level catch: surfaces the error to the user/caller rather than crashing the request.
            catch (Exception e)
            {
                TempData["error"] = "Error setting default for workload zone: " + e.Message;
            }
            return RedirectToAction("Index");
        }

        public async Task UnsetDefault(string id)
        {
            LogDebug($"UnsetDefault called. Id={id}");
            try
            {
                LandscapeModel existingDefault = await GetDefault();
                if (existingDefault != null && existingDefault.Id != id)
                {
                    existingDefault.IsDefault = false;
                    await _landscapeService.UpdateAsync(new LandscapeEntity(existingDefault));
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
