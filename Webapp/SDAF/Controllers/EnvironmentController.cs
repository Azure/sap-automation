using AutomationForm.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System;
using System.Threading.Tasks;

namespace AutomationForm.Controllers
{
  public class EnvironmentController : Controller
  {
    private readonly IConfiguration _configuration;
    private RestHelper restHelper;

    public EnvironmentController(IConfiguration configuration)
    {
      _configuration = configuration;
      restHelper = new RestHelper(configuration);
    }

    [ActionName("Index")]
    public IActionResult Index()
    {
      EnvironmentModel[] variableGroups = new EnvironmentModel[0];
      try
      {
        variableGroups = restHelper.GetVariableGroups().Result;
      }
      catch (Exception e)
      {
        TempData["error"] = e.Message;
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
      catch
      {
        return null;
      }
    }

    [ActionName("Create")]
    public ActionResult Create()
    {
      return View(new EnvironmentModel());
    }

    [HttpPost]
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
        ModelState.AddModelError("EnvironmentId", "Error creating environment: " + e.Message);
      }
      return View(environment);
    }

    [ActionName("Edit")]
    public ActionResult Edit(int id)
    {
      try
      {
        EnvironmentModel environment = restHelper.GetVariableGroup(id).Result;
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
        ModelState.AddModelError("EnvironmentId", "Error editing environment: " + e.Message);
      }
      return View(environment);
    }
  }
}
