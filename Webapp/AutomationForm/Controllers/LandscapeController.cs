using Microsoft.AspNetCore.Mvc;
using AutomationForm.Models;
using AutomationForm.Services;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc.Rendering;
using System;
using Microsoft.AspNetCore.Http;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Net;

namespace AutomationForm.Controllers
{
    public class LandscapeController : Controller
    {

        private readonly ILandscapeService<LandscapeModel> _landscapeService;
        private LandscapeViewModel landscapeView;
        private readonly IConfiguration _configuration;

        public LandscapeController(ILandscapeService<LandscapeModel> landscapeService, IConfiguration configuration)
        {
            _landscapeService = landscapeService;
            _configuration = configuration;
            landscapeView = SetViewData();
        }
        private LandscapeViewModel SetViewData()
        {
            landscapeView = new LandscapeViewModel();
            landscapeView.Landscape = new LandscapeModel();
            try
            {
                ParameterGroupingModel basicParameterArray = Helper.ReadJson("ParameterDetails/BasicLandscapeDetails.json");
                ParameterGroupingModel advancedParameterArray = Helper.ReadJson("ParameterDetails/AdvancedLandscapeDetails.json");
                ParameterGroupingModel expertParameterArray = Helper.ReadJson("ParameterDetails/ExpertLandscapeDetails.json");

                landscapeView.ParameterGroupings = new ParameterGroupingModel[] { basicParameterArray, advancedParameterArray, expertParameterArray };
            }
            catch
            {
                landscapeView.ParameterGroupings = new ParameterGroupingModel[0];
            }

            return landscapeView;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            return View(await _landscapeService.GetNAsync(10));
        }

        [HttpGet]
        public async Task<ActionResult> GetWorkloadZones()
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                List<LandscapeModel> landscapes = await _landscapeService.GetAllAsync();

                foreach (LandscapeModel l in landscapes)
                {
                    options.Add(new SelectListItem
                    {
                        Text = l.Id,
                        Value = l.Id
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
        public async Task<ActionResult<LandscapeModel>> GetById(string id)
        {
            LandscapeModel landscape = await _landscapeService.GetByIdAsync(id);
            if (landscape == null) return NotFound();

            return landscape;
        }

        [ActionName("Create")]
        public IActionResult Create()
        {
            return View(landscapeView);
        }

        [HttpPost]
        [ActionName("Create")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateAsync(LandscapeModel landscape)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    landscape.Id = (landscape.environment + "-" + Helper.MapRegion(landscape.location) + "-" + landscape.network_logical_name + "-infrastructure").ToUpper();
                    await _landscapeService.CreateAsync(landscape);
                    TempData["success"] = "Successfully created landscape " + landscape.Id;
                    return RedirectToAction("Index");
                }
                catch
                {
                    ModelState.AddModelError("LandscapeId", "Error creating landscape (most likely it already exists)");
                }
            }

            landscapeView.Landscape = landscape;

            return View(landscapeView);
        }

        [ActionName("Deploy")]
        public async Task<IActionResult> DeployAsync(string id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            LandscapeModel landscape = await _landscapeService.GetByIdAsync(id);
            if (landscape == null)
            {
                return NotFound();
            }

            return View(landscape);
        }

        [HttpPost]
        [ActionName("Deploy")]
        public async Task<RedirectToActionResult> DeployConfirmedAsync(string id)
        {
            try
            {
                LandscapeModel landscape = GetById(id).Result.Value;

                string path = $"{id}.tfvars";
                string content = Helper.ConvertToTerraform(landscape);
                string pipelineId = _configuration["WORKLOADZONE_PIPELINE_ID"];

                await Helper.UpdateRepo(path, content, _configuration);
                await Helper.TriggerPipeline(pipelineId, _configuration);
                
                TempData["success"] = "Successfully deployed landscape " + id;
            }
            catch
            {
                TempData["error"] = "Error deploying landscape " + id;
            }
            return RedirectToAction("Index");
        }

        [ActionName("Delete")]
        public async Task<IActionResult> DeleteAsync(string id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            LandscapeModel landscape = await _landscapeService.GetByIdAsync(id);
            if (landscape == null)
            {
                return NotFound();
            }

            return View(landscape);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmedAsync(string id)
        {
            await _landscapeService.DeleteAsync(id);
            TempData["success"] = "Successfully deleted landscape " + id;
            return RedirectToAction("Index");
        }

        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            LandscapeModel landscape = await _landscapeService.GetByIdAsync(id);
            if (landscape == null)
            {
                return NotFound();
            }

            landscapeView.Landscape = landscape;

            return View(landscapeView);
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditAsync(LandscapeModel landscape)
        {
            if (ModelState.IsValid)
            {
                string newId = (landscape.environment + "-" + Helper.MapRegion(landscape.location) + "-" + landscape.network_logical_name + "-infrastructure").ToUpper();
                if (landscape.Id == null) landscape.Id = newId;
                if (newId != landscape.Id)
                {
                    return SubmitNewAsync(landscape).Result;
                }
                else
                {
                    await _landscapeService.UpdateAsync(landscape);
                    TempData["success"] = "Successfully updated landscape " + landscape.Id;
                    return RedirectToAction("Index");
                }
            }

            landscapeView.Landscape = landscape;

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
                    landscape.Id = (landscape.environment + "-" + Helper.MapRegion(landscape.location) + "-" + landscape.network_logical_name + "-infrastructure").ToUpper();
                    await _landscapeService.CreateAsync(landscape);
                    TempData["success"] = "Successfully created landscape " + landscape.Id;
                    return RedirectToAction("Index");
                }
                catch
                {
                    ModelState.AddModelError("LandscapeId", "Error creating landscape (most likely it already exists)");
                }
            }

            landscapeView.Landscape = landscape;

            return View("Edit", landscapeView);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id)
        {
            return View(await _landscapeService.GetByIdAsync(id));
        }
        
    }
}