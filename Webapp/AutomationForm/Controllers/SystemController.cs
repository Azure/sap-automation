using Microsoft.AspNetCore.Mvc;
using AutomationForm.Models;
using AutomationForm.Services;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System;

namespace AutomationForm.Controllers
{
    public class SystemController : Controller
    {

        private readonly ILandscapeService<SystemModel> _systemService;
        private SystemViewModel systemView;
        private readonly IConfiguration _configuration;

        public SystemController(ILandscapeService<SystemModel> systemService, IConfiguration configuration)
        {
            _systemService = systemService;
            _configuration = configuration;
            systemView = SetViewData();
        }
        private SystemViewModel SetViewData()
        {
            systemView = new SystemViewModel();
            systemView.System = new SystemModel();
            try
            {
                ParameterGroupingModel basicParameterArray = Helper.ReadJson("ParameterDetails/BasicSystemDetails.json");
                ParameterGroupingModel advancedParameterArray = Helper.ReadJson("ParameterDetails/AdvancedSystemDetails.json");
                ParameterGroupingModel expertParameterArray = Helper.ReadJson("ParameterDetails/ExpertSystemDetails.json");

                systemView.ParameterGroupings = new ParameterGroupingModel[] { basicParameterArray, advancedParameterArray, expertParameterArray };
            }
            catch
            {
                systemView.ParameterGroupings = new ParameterGroupingModel[0];
            }

            return systemView;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            return View(await _systemService.GetNAsync(10));
        }

        [HttpGet]
        public async Task<ActionResult<SystemModel>> GetById(string id)
        {
            var system = await _systemService.GetByIdAsync(id);
            if (system == null) return NotFound();

            return system;
        }

        [ActionName("Create")]
        public IActionResult Create()
        {
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
                    system.Id = (system.environment + "-" + Helper.MapRegion(system.location) + "-" + system.network_logical_name + "-" + system.sid).ToUpper();
                    await _systemService.CreateAsync(system);
                    TempData["success"] = "Successfully created sytsem " + system.Id;
                    return RedirectToAction("Index");
                }
                catch
                {
                    ModelState.AddModelError("SystemId", "Error creating system (most likely it already exists)");
                }
            }

            systemView.System = system;

            return View(systemView);
        }

        [ActionName("Deploy")]
        public async Task<IActionResult> DeployAsync(string id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            SystemModel system = await _systemService.GetByIdAsync(id);
            if (system == null)
            {
                return NotFound();
            }

            return View(system);
        }

        [HttpPost]
        [ActionName("Deploy")]
        public async Task<RedirectToActionResult> DeployConfirmedAsync(string id)
        {
            try
            {
                SystemModel system = GetById(id).Result.Value;

                string path = $"samples/WORKSPACES/SYSTEM/{id}/{id}.tfvars";
                string content = Helper.ConvertToTerraform(system);
                string pipelineId = _configuration["SYSTEM_PIPELINE_ID"];
                bool isSystem = true;

                await Helper.UpdateRepo(path, content, _configuration);
                await Helper.TriggerPipeline(pipelineId, id, _configuration, isSystem);
                
                TempData["success"] = "Successfully deployed system " + id;
            }
            catch
            {
                TempData["error"] = "Error deploying system " + id;
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

            SystemModel system = await _systemService.GetByIdAsync(id);
            if (system == null)
            {
                return NotFound();
            }

            return View(system);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmedAsync(string id)
        {
            await _systemService.DeleteAsync(id);
            TempData["success"] = "Successfully deleted system " + id;
            return RedirectToAction("Index");
        }

        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            SystemModel system = await _systemService.GetByIdAsync(id);
            if (system == null)
            {
                return NotFound();
            }

            systemView.System = system;

            return View(systemView);
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditAsync(SystemModel system)
        {
            if (ModelState.IsValid)
            {
                string newId = (system.environment + "-" + Helper.MapRegion(system.location) + "-" + system.network_logical_name + "-" + system.sid).ToUpper();
                if (system.Id == null) system.Id = newId;
                if (newId != system.Id)
                {
                    return SubmitNewAsync(system).Result;
                }
                else
                {
                    await _systemService.UpdateAsync(system);
                    TempData["success"] = "Successfully updated system " + system.Id;
                    return RedirectToAction("Index");
                }
            }

            systemView.System = system;

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
                    system.Id = (system.environment + "-" + Helper.MapRegion(system.location) + "-" + system.network_logical_name + "-" + system.sid).ToUpper();
                    await _systemService.CreateAsync(system);
                    TempData["success"] = "Successfully created system " + system.Id;
                    return RedirectToAction("Index");
                }
                catch
                {
                    ModelState.AddModelError("SystemId", "Error creating system (most likely it already exists)");
                }
            }

            systemView.System = system;

            return View("Edit", systemView);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id)
        {
            return View(await _systemService.GetByIdAsync(id));
        }

    }
}