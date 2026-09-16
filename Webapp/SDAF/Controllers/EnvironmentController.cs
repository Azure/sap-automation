// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace SDAFWebApp.Controllers
{
    public class EnvironmentController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly RestHelper restHelper;
        private readonly ILogger<EnvironmentController> _logger;

        public EnvironmentController(
            IConfiguration configuration,
            RestHelper restHelper,
            ILogger<EnvironmentController> logger)
        {
            _configuration = configuration;
            this.restHelper = restHelper;
            _logger = logger;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            EnvironmentModel[] variableGroups = Array.Empty<EnvironmentModel>();
            try
            {
                variableGroups = await restHelper.GetVariableGroups();
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to retrieve environments");
                TempData["error"] = "Environments could not be retrieved.";
            }
            return View(variableGroups);
        }

        [HttpGet]
        public async Task<ActionResult> GetEnvironments()
        {
            try
            {
                return Json(await restHelper.GetEnvironmentsList());
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to retrieve environments");
                return StatusCode(503, new { error = "Environments are temporarily unavailable." });
            }
        }

        [ActionName("Create")]
        public ActionResult Create()
        {
            return View(new EnvironmentModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [ActionName("Create")]
        public async Task<ActionResult> CreateAsync(EnvironmentModel environment, string newName, string description)
        {
            try
            {
                await restHelper.CreateVariableGroup(environment, newName, description);
                TempData["success"] = "Successfully created environment: " + newName;
                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to create environment");
                ModelState.AddModelError("EnvironmentId", "The environment could not be created.");
            }
            return View(environment);
        }

        [ActionName("Edit")]
        public async Task<ActionResult> EditAsync(int id)
        {
            try
            {
                EnvironmentModel environment = await restHelper.GetVariableGroup(id);
                return View(environment);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to load environment");
                TempData["error"] = "The environment could not be loaded.";
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [ActionName("Edit")]
        public async Task<ActionResult> EditAsync(EnvironmentModel environment, string newName, string description)
        {
            try
            {
                await restHelper.UpdateVariableGroup(environment, newName, description);
                TempData["success"] = "Successfully edited environment: " + newName;
                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to edit environment");
                ModelState.AddModelError("EnvironmentId", "The environment could not be updated.");
            }
            return View(environment);
        }
    }
}
