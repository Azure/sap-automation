using AutomationForm.Models;
using AutomationForm.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Microsoft.Net.Http.Headers;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace AutomationForm.Controllers
{
  public class SystemController : Controller
  {

    private readonly ITableStorageService<SystemEntity> _systemService;
    private readonly ITableStorageService<AppFile> _appFileService;
    private FormViewModel<SystemModel> systemView;
    private readonly IConfiguration _configuration;
    private readonly RestHelper restHelper;

    private ImageDropdown[] imagesOffered;
    private List<SelectListItem> imageOptions;
    private Dictionary<string, Image> imageMapping;

    public SystemController(ITableStorageService<SystemEntity> systemService, ITableStorageService<AppFile> appFileService, IConfiguration configuration)
    {
      _systemService = systemService;
      _appFileService = appFileService;
      _configuration = configuration;
      restHelper = new RestHelper(configuration);
      systemView = SetViewData();

      imagesOffered = Helper.GetOfferedImages(_appFileService).Result;
      InitializeImageOptionsAndMapping();
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
        systemView.ParameterGroupings = new Grouping[0];
      }

      return systemView;
    }

    [ActionName("Index")]
    public async Task<IActionResult> Index()
    {
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
      catch (Exception e)
      {
        TempData["error"] = "Error retrieving existing systems: " + e.Message;
      }

      return View(systemIndex);
    }

    [HttpGet]
    public async Task<SystemModel> GetById(string id, string partitionKey)
    {
      if (id == null || partitionKey == null) throw new ArgumentNullException();
      var systemEntity = await _systemService.GetByIdAsync(id, partitionKey);
      if (systemEntity == null || systemEntity.System == null) throw new KeyNotFoundException();
      SystemModel s = null;
      try
      {
        s = JsonConvert.DeserializeObject<SystemModel>(systemEntity.System);
      }
      catch
      {

      }
      AppFile file = null;
      try
      {
        file = await _appFileService.GetByIdAsync(id + "_custom_naming.json", partitionKey);
        s.name_override_file = id + "_custom_naming.json";
      }
      catch
      {

      }

      file = null;
      try
      {
        file = await _appFileService.GetByIdAsync(id + "_custom_sizes.json", partitionKey);
        s.custom_disk_sizes_filename = id + "_custom_sizes.json";
        s.database_size = "Custom";
      }
      catch
      {

      }

      return s;
    }

    [HttpGet]
    public async Task<SystemModel> GetDefault()
    {
      SystemEntity defaultSystem = await _systemService.GetDefault();
      if (defaultSystem == null || defaultSystem.System == null) return null;
      return JsonConvert.DeserializeObject<SystemModel>(defaultSystem.System);
    }

    [HttpGet]
    public async Task<ActionResult> GetDefaultJson()
    {
      SystemEntity systemEntity = await _systemService.GetDefault();
      if (systemEntity == null) return NotFound();
      return Json(systemEntity.System);
    }

    public void InitializeImageOptionsAndMapping()
    {
      imageMapping = new Dictionary<string, Image>();
      imageOptions = new List<SelectListItem>
            {
                new SelectListItem()
            };

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
      if (name != null && imageMapping.ContainsKey(name))
      {
        Image image = imageMapping[name];
        return Json(image);
      }
      else
      {
        throw new Exception();
      }
    }

    [ActionName("Create")]
    public IActionResult Create()
    {
      ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
      ViewBag.ImageOptions = imageOptions;
      return View(systemView);
    }

    [HttpPost]
    [ActionName("Create")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateAsync(SystemModel system)
    {
      if (ModelState.IsValid)
      {
        try
        {
          if (system.IsDefault)
          {
            await UnsetDefault(system.Id);
          }
          system.Id = Helper.GenerateId(system);
          SystemEntity systemEntity = new(system);
          await _systemService.CreateAsync(systemEntity);
          TempData["success"] = "Successfully created system " + system.Id;
          return RedirectToAction("Index");
        }
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
    [ActionName("Deploy")]
    public async Task<RedirectToActionResult> DeployConfirmedAsync(string id, string partitionKey, Templateparameters parameters)
    {
      try
      {
        SystemModel system = await GetById(id, partitionKey);

        AppFile file = null;
        try
        {
          file = await _appFileService.GetByIdAsync(id + "_custom_naming.json", partitionKey);
          system.name_override_file = id + "_custom_naming.json";
          var stream = new MemoryStream(file.Content);

          string thisContent = System.Text.Encoding.UTF8.GetString(stream.ToArray());
          string pathForNaming = $"/SYSTEM/{id}/{id}_custom_naming.json";

          await restHelper.UpdateRepo(pathForNaming, thisContent);
        }
        catch
        {

        }

        file = null;
        try
        {
          file = await _appFileService.GetByIdAsync(id + "_custom_sizes.json", partitionKey);
          var stream = new MemoryStream(file.Content);

          system.custom_disk_sizes_filename = id + "_custom_sizes.json";
          system.database_size = "Custom";

          string thisContent = System.Text.Encoding.UTF8.GetString(stream.ToArray());
          string pathForNaming = $"/SYSTEM/{id}/{id}_custom_sizes.json";

          await restHelper.UpdateRepo(pathForNaming, thisContent);
        }
        catch
        {

        }

        string path = $"/SYSTEM/{id}/{id}.tfvars";
        string content = Helper.ConvertToTerraform(system);

        await restHelper.UpdateRepo(path, content);


        string pipelineId = _configuration["SYSTEM_PIPELINE_ID"];
        string branch = _configuration["SourceBranch"];
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
      }
      catch (Exception e)
      {
        TempData["error"] = "Error deploying system " + id + ": " + e.Message;
      }
      return RedirectToAction("Index");
    }

    [ActionName("Install")]
    public async Task<IActionResult> InstallAsync(string id, string partitionKey)
    {
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
    [ActionName("Install")]
    public async Task<IActionResult> InstallConfirmedAsync(string id, string partitionKey, Templateparameters parameters)
    {
      try
      {
        SystemModel system = await GetById(id, partitionKey);

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
      }
      catch (Exception e)
      {
        TempData["error"] = "Error triggering SAP installation pipeline for system " + id + ": " + e.Message;
      }
      return RedirectToAction("Index");
    }

    [ActionName("Delete")]
    public async Task<IActionResult> DeleteAsync(string id, string partitionKey)
    {
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
      await _systemService.DeleteAsync(id, partitionKey);
      TempData["success"] = "Successfully deleted system " + id;
      return RedirectToAction("Index");
    }

    [ActionName("Edit")]
    public async Task<IActionResult> EditAsync(string id, string partitionKey)
    {
      try
      {
        SystemModel system = await GetById(id, partitionKey);
        systemView.SapObject = system;

        ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
        ViewBag.ImageOptions = imageOptions;

        return View(systemView);
      }
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
      if (ModelState.IsValid)
      {
        try
        {
          string newId = Helper.GenerateId(system);
          if (system.Id == null) system.Id = newId;
          if (newId != system.Id)
          {
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
            return RedirectToAction("Index");


          }
          else
          {
            if (system.IsDefault)
            {
              await UnsetDefault(system.Id);
            }
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
            return RedirectToAction("Index");
          }
        }
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
      if (ModelState.IsValid)
      {
        try
        {
          if (system.IsDefault)
          {
            await UnsetDefault(system.Id);
          }
          system.Id = Helper.GenerateId(system);
          await _systemService.CreateAsync(new SystemEntity(system));
          TempData["success"] = "Successfully created system " + system.Id;
          return RedirectToAction("Index");
        }
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
      try
      {
        SystemModel system = await GetById(id, partitionKey);
        systemView.SapObject = system;
        return View(systemView);
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
      try
      {
        SystemModel system = GetById(id, partitionKey).Result;

        string path = $"{id}.tfvars";
        string content = Helper.ConvertToTerraform(system);

        var stream = new MemoryStream(Encoding.UTF8.GetBytes(content));
        return new FileStreamResult(stream, new MediaTypeHeaderValue("text/plain"))
        {
          FileDownloadName = path
        };
      }
      catch (Exception e)
      {
        TempData["error"] = "Something went wrong downloading file " + id + ": " + e.Message;
        return RedirectToAction("Index");
      }
    }

    [ActionName("MakeDefault")]
    public async Task<IActionResult> MakeDefault(string id, string partitionKey)
    {
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
      catch (Exception e)
      {
        ModelState.AddModelError("SystemId", "Error setting default for system: " + e.Message);
      }
      return RedirectToAction("Index");
    }

    public async Task UnsetDefault(string id)
    {
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
      catch (Exception e)
      {
        throw new Exception("Error unsetting the current default object: " + e.Message);
      }
    }

  }
}
