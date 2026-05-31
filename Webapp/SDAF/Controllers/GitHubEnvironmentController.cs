// Licensed under the MIT License.

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Octokit;
using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace SDAFWebApp.Controllers
{
    public class GitHubEnvironmentController : Controller
    {
        private readonly IConfiguration _configuration;
        private GitHubEnvironmentHelper _helper;
        private readonly string _ghOrganization;
        private readonly string _ghRepository;
        private readonly string _ghToken;
        private readonly string _sdafControlPlaneName;

        public GitHubEnvironmentController(IConfiguration configuration)
        {
            _configuration = configuration;
            _ghOrganization = configuration["GITHUB_REPOSITORY"].Split("/")[0];
            _ghRepository = configuration["GITHUB_REPOSITORY"].Split("/")[1];
            _ghToken = configuration["GITHUB_PAT"];
            _sdafControlPlaneName = configuration["CONTROL_PLANE_NAME"];

            _helper = new GitHubEnvironmentHelper(_ghToken, _ghOrganization, _ghRepository);
        }

        [ActionName("Index")]
        public async Task<IActionResult> IndexAsync()
        {
            GHEnvironmentModel[] ghEnvironments = Array.Empty<GHEnvironmentModel>();
            try
            {
                var environments = await _helper.ListEnvironmentsAsync();
                ghEnvironments = environments.ConvertAll(e => new GHEnvironmentModel
                {
                    Id = e.Id,
                    Name = e.Name,
                    Description = e.Description,
                    SdafControlPlaneEnvironment = e.SdafControlPlaneEnvironment
                }).ToArray();
            }
            catch (Exception e)
            {
                TempData["error"] = e.Message;
            }
            return View(ghEnvironments);
        }

        [HttpGet]
        public async Task<ActionResult> GetEnvironments()
        {
            try
            {
                return Json(await _helper.ListEnvironmentsAsync());
            }
            catch
            {
                return null;
            }
        }

        [ActionName("Create")]
        public ActionResult Create()
        {
            return View(new GHEnvironmentModel());
        }

        [HttpPost]
        [ActionName("Create")]
        public async Task<ActionResult> CreateAsync(EnvironmentModel environment, string newName, string description)
        {
            try
            {
                var githubClient = new Octokit.GitHubClient(new Octokit.ProductHeaderValue("SDAF"));
                githubClient.Credentials = new Octokit.Credentials(_ghToken);

                var workflowDispatch = new Octokit.CreateWorkflowDispatch("main")
                {
                    Inputs = new Dictionary<string, object>
                            {
                                { "workload_environment", newName },
                                { "control_plane_name", _sdafControlPlaneName }
                            }

            };
                try
                {
                    await githubClient.Actions.Workflows.CreateDispatch(_ghOrganization, _ghRepository, "02-create-workload-environment.yml", workflowDispatch);
                }
                catch (Octokit.ApiException ex)
                {
                    throw new HttpRequestException($"Failed to trigger GitHub workflow: {ex.Message}");
                }

                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                ModelState.AddModelError("EnvironmentId", "Error creating environment: " + e.Message);
            }
            return View(environment);
        }

        [ActionName("Edit")]
        public ActionResult Edit(string name)
        {
            try
            {
                GitHubEnvironment ghEnvironment = _helper.GetEnvironmentAsync(name).Result;
                GHEnvironmentModel environment = new GHEnvironmentModel
                {
                    Id = ghEnvironment.Id,
                    Name = ghEnvironment.Name,
                    Description = ghEnvironment.Description,
                    SdafControlPlaneEnvironment = ghEnvironment.SdafControlPlaneEnvironment
                };  
                return View(environment);
            }
            catch (Exception e)
            {
                TempData["error"] = e.Message;
                return RedirectToAction("Index");
            }
        }

        [HttpPost]
        [ActionName("Edit")]
        public ActionResult Edit(EnvironmentModel environment, string newName, string description)
        {
            try
            {
                // await restHelper.UpdateVariableGroup(environment, newName, description);
                TempData["success"] = "Successfully edited environment: " + newName;
                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                ModelState.AddModelError("EnvironmentId", "Error editing environment: " + e.Message);
            }
            return View(environment);
        }
    }
}
