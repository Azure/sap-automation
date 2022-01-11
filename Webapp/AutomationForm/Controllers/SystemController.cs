using Microsoft.AspNetCore.Mvc;
using AutomationForm.Models;
using AutomationForm.Services;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace AutomationForm.Controllers
{
    public class SystemController : Controller
    {

        private readonly ILandscapeService<SystemModel> _systemService;
        private SystemViewModel systemView;
        private readonly HelperController<SystemModel> helper;
        private readonly IConfiguration _configuration;

        public SystemController(ILandscapeService<SystemModel> systemService, IConfiguration configuration)
        {
            _systemService = systemService;
            _configuration = configuration;
            helper = new HelperController<SystemModel>();
            systemView = SetViewData();
        }
        public SystemViewModel SetViewData()
        {
            systemView = new SystemViewModel();
            systemView.System = new SystemModel();
            try
            {
                ParameterGroupingModel basicParameterArray = helper.ReadJson("ParameterDetails/BasicSystemDetails.json");
                ParameterGroupingModel advancedParameterArray = helper.ReadJson("ParameterDetails/AdvancedSystemDetails.json");
                ParameterGroupingModel expertParameterArray = helper.ReadJson("ParameterDetails/ExpertSystemDetails.json");

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
                    system.Id = (system.environment + "-" + helper.mapRegion(system.location) + "-" + system.resource_group_name + "-" + system.sid).ToUpper();
                    await _systemService.CreateAsync(system);
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

                string path = $"{id}.tfvars";
                string content = helper.ConvertToTerraform(system);
                string pipelineId = "3";

                await helper.UpdateRepo(path, content, _configuration);
                await helper.TriggerPipeline(pipelineId, _configuration);
                
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
                await _systemService.UpdateAsync(system);
                TempData["success"] = "Successfully updated system " + system.Id;
                return RedirectToAction("Index");
            }

            systemView.System = system;

            return View(systemView);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id)
        {
            return View(await _systemService.GetByIdAsync(id));
        }

    }
}