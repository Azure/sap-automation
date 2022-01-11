using Microsoft.AspNetCore.Mvc;
using AutomationForm.Models;
using AutomationForm.Services;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace AutomationForm.Controllers
{
    public class LandscapeController : Controller
    {

        private readonly ILandscapeService<LandscapeModel> _landscapeService;
        private LandscapeViewModel landscapeView;
        private readonly HelperController<LandscapeModel> helper;
        private readonly IConfiguration _configuration;

        public LandscapeController(ILandscapeService<LandscapeModel> landscapeService, IConfiguration configuration)
        {
            _landscapeService = landscapeService;
            _configuration = configuration;
            helper = new HelperController<LandscapeModel>();
            landscapeView = SetViewData();
        }
        public LandscapeViewModel SetViewData()
        {
            landscapeView = new LandscapeViewModel();
            landscapeView.Landscape = new LandscapeModel();
            try
            {
                ParameterGroupingModel basicParameterArray = helper.ReadJson("ParameterDetails/BasicLandscapeDetails.json");
                ParameterGroupingModel advancedParameterArray = helper.ReadJson("ParameterDetails/AdvancedLandscapeDetails.json");
                ParameterGroupingModel expertParameterArray = helper.ReadJson("ParameterDetails/ExpertLandscapeDetails.json");

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

        // workload_zone dropdown
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
                    landscape.Id = (landscape.environment + "-" + helper.mapRegion(landscape.location) + "-" + landscape.logical_network_name + "-infrastructure").ToUpper();
                    await _landscapeService.CreateAsync(landscape);
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
                string content = helper.ConvertToTerraform(landscape);
                string pipelineId = "2";

                await helper.UpdateRepo(path, content, _configuration);
                await helper.TriggerPipeline(pipelineId, _configuration);
                
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
                await _landscapeService.UpdateAsync(landscape);
                TempData["success"] = "Successfully updated landscape " + landscape.Id;
                return RedirectToAction("Index");
            }

            landscapeView.Landscape = landscape;

            return View(landscapeView);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id)
        {
            return View(await _landscapeService.GetByIdAsync(id));
        }

    }
}