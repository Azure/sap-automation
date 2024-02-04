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
  public class LandscapeController : Controller
  {

    private readonly ITableStorageService<LandscapeEntity> _landscapeService;
    private readonly ITableStorageService<AppFile> _appFileService;
    private FormViewModel<LandscapeModel> landscapeView;
    private readonly IConfiguration _configuration;
    private RestHelper restHelper;
    private readonly ImageDropdown[] imagesOffered;
    private List<SelectListItem> imageOptions;
    private Dictionary<string, Image> imageMapping;
    private readonly string sdafControlPlaneEnvironment;
    private readonly string sdafControlPlaneLocation;

    public LandscapeController(ITableStorageService<LandscapeEntity> landscapeService, ITableStorageService<AppFile> appFileService, IConfiguration configuration)
    {
      _landscapeService = landscapeService;
      _appFileService = appFileService;
      _configuration = configuration;
      restHelper = new RestHelper(configuration);
      landscapeView = SetViewData();
      imagesOffered = Helper.GetOfferedImages(_appFileService).Result;
      InitializeImageOptionsAndMapping();
      sdafControlPlaneEnvironment = configuration["CONTROLPLANE_ENV"];
      sdafControlPlaneLocation = configuration["CONTROLPLANE_LOC"];
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
        landscapeView.ParameterGroupings = new Grouping[0];
      }

      return landscapeView;
    }

    [ActionName("Index")]
    public async Task<IActionResult> Index()
    {
      SapObjectIndexModel<LandscapeModel> landscapeIndex = new();

      try
      {
        List<LandscapeEntity> landscapeEntities = await _landscapeService.GetAllAsync();
        List<LandscapeModel> landscapes = landscapeEntities.FindAll(l => l.Landscape != null).ConvertAll(l => JsonConvert.DeserializeObject<LandscapeModel>(l.Landscape));
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
    public async Task<ActionResult> GetWorkloadZones()
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        List<LandscapeEntity> landscapeEntities = await _landscapeService.GetAllAsync();

        foreach (LandscapeEntity e in landscapeEntities)
        {
          options.Add(new SelectListItem
          {
            Text = e.RowKey,
            Value = e.RowKey
          });
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
      if (id == null || partitionKey == null) throw new ArgumentNullException();
      var landscapeEntity = await _landscapeService.GetByIdAsync(id, partitionKey);
      if (landscapeEntity == null || landscapeEntity.Landscape == null) throw new KeyNotFoundException();
      return JsonConvert.DeserializeObject<LandscapeModel>(landscapeEntity.Landscape);
    }

    // Format correctly for javascript consumption
    [HttpGet]
    public async Task<ActionResult> GetByIdJson(string id)
    {
      string environment = id[..id.IndexOf('-')];
      LandscapeEntity landscape = await _landscapeService.GetByIdAsync(id, environment);
      if (landscape == null || landscape.Landscape == null) return NotFound();
      return Json(landscape.Landscape);
    }

    [HttpGet]
    public async Task<LandscapeModel> GetDefault()
    {
      LandscapeEntity defaultLandscape = await _landscapeService.GetDefault();
      if (defaultLandscape == null || defaultLandscape.Landscape == null) return null;
      return JsonConvert.DeserializeObject<LandscapeModel>(defaultLandscape.Landscape);
    }

    [HttpGet]
    public ActionResult GetDefaultJson()
    {
      LandscapeEntity landscapeEntity = _landscapeService.GetDefault().Result;
      if (landscapeEntity == null) return NotFound();
      return Json(landscapeEntity.Landscape);
    }

    [ActionName("Create")]
    public IActionResult Create()
    {
      ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
      ViewBag.ImageOptions = imageOptions;
      return View(landscapeView);
    }

    [HttpPost]
    [ActionName("Create")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateAsync(LandscapeModel landscape)
    {
      if (ModelState.IsValid || landscape.IsDefault)
      {
        try
        {
          if (landscape.IsDefault)
          {
            await UnsetDefault(landscape.Id);
          }
          landscape.Id = Helper.GenerateId(landscape);
          await _landscapeService.CreateAsync(new LandscapeEntity(landscape));
          TempData["success"] = "Successfully created workload zone " + landscape.Id;
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
      try
      {
        LandscapeModel landscape = await GetById(id, partitionKey);
        landscape.controlPlaneEnvironment = sdafControlPlaneEnvironment;
        landscape.controlPlaneLocation = sdafControlPlaneLocation;
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
    [ActionName("Deploy")]
    public async Task<RedirectToActionResult> DeployConfirmedAsync(string id, string partitionKey, Templateparameters parameters)
    {
      try
      {
        LandscapeModel landscape = await GetById(id, partitionKey);

        string path = $"/LANDSCAPE/{id}/{id}.tfvars";
        string content = Helper.ConvertToTerraform(landscape);

        await restHelper.UpdateRepo(path, content);

        string pipelineId = _configuration["WORKLOADZONE_PIPELINE_ID"];
        string branch = _configuration["SourceBranch"];
        parameters.workload_zone = id;
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

        TempData["success"] = "Successfully triggered workload zone deployment pipeline for " + id;
      }
      catch (Exception e)
      {
        TempData["error"] = "Error deploying workload zone " + id + ": " + e.Message;
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
      await _landscapeService.DeleteAsync(id, partitionKey);
      TempData["success"] = "Successfully deleted workload zone " + id;
      return RedirectToAction("Index");
    }

    [ActionName("Edit")]
    public async Task<IActionResult> EditAsync(string id, string partitionKey)
    {
      try
      {
        ActionResult<LandscapeModel> result = await GetById(id, partitionKey);
        LandscapeModel landscape = result.Value;
        landscapeView.SapObject = landscape;
        ViewBag.ValidImageOptions = (imagesOffered.Length != 0);
        ViewBag.ImageOptions = imageOptions;
        return View(landscapeView);
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
    public async Task<IActionResult> EditAsync(LandscapeModel landscape)
    {
      if (ModelState.IsValid)
      {
        try
        {
          string newId = Helper.GenerateId(landscape);
          if (landscape.Id == null) landscape.Id = newId;
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

            return RedirectToAction("Index");
          }
          else
          {
            if (landscape.IsDefault)
            {
              await UnsetDefault(landscape.Id);
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

            return RedirectToAction("Index");
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
      if (ModelState.IsValid)
      {
        try
        {
          if (landscape.IsDefault)
          {
            await UnsetDefault(landscape.Id);
          }
          landscape.Id = Helper.GenerateId(landscape);
          await _landscapeService.CreateAsync(new LandscapeEntity(landscape));
          TempData["success"] = "Successfully created workload zone " + landscape.Id;
          string id = landscape.Id;
          string path = $"/LANDSCAPE/{id}/{id}.tfvars";
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
      try
      {
        LandscapeModel landscape = GetById(id, partitionKey).Result;

        string path = $"{id}.tfvars";
        string content = Helper.ConvertToTerraform(landscape);

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
        await UnsetDefault(id);

        ActionResult<LandscapeModel> result = await GetById(id, partitionKey);
        LandscapeModel landscape = result.Value;

        landscape.IsDefault = true;
        LandscapeEntity landscapeEntity = new(landscape);
        await _landscapeService.UpdateAsync(landscapeEntity);
        TempData["success"] = id + " is now the default workload zone";
      }
      catch (Exception e)
      {
        TempData["error"] = "Error setting default for workload zone: " + e.Message;
      }
      return RedirectToAction("Index");
    }

    public async Task UnsetDefault(string id)
    {
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
      catch (Exception e)
      {
        throw new Exception("Error unsetting the current default object: " + e.Message);
      }
    }

  }
}
