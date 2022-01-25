using AutomationForm.Models;
using AutomationForm.Services;
using AutomationForm.Controllers;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace AutomationForm.Controllers
{
    public class FileController : Controller
    {
        private readonly ILandscapeService<AppFile> _appFileService;
        private readonly ILandscapeService<LandscapeModel> _landscapeService;
        private readonly ILandscapeService<SystemModel> _systemService;

        public FileController(ILandscapeService<AppFile> appFileService, ILandscapeService<LandscapeModel> landscapeService, ILandscapeService<SystemModel> systemService)
        {
            _appFileService = appFileService;
            _landscapeService = landscapeService;
            _systemService = systemService;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            return View(await _appFileService.GetNAsync(10));
        }

        [ActionName("Upload")]
        public IActionResult UploadAsync()
        {
            return View();
        }

        [HttpPost]
        [ActionName("Upload")]
        public async Task<IActionResult> UploadAsync(FileUploadModel fileUpload)
        {
            // Perform an initial check to catch FileUpload class
            // attribute violations.
            if (ModelState.IsValid)
            {
                try
                {
                    string[] permittedExtensions = { ".tfvars" };
                    long fileSizeLimit = 2097152;
                    foreach (var formFile in fileUpload.FormFiles)
                    {
                        byte[] formFileContent =
                            await Helper.ProcessFormFile(formFile, ModelState, permittedExtensions, fileSizeLimit);

                        // Perform a second check to catch ProcessFormFile method
                        // violations. If any validation check fails, return to the
                        // page.
                        if (!ModelState.IsValid)
                        {
                            return View();
                        }

                        // **WARNING!**
                        // In the following example, the file is saved without
                        // scanning the file's contents. In most production
                        // scenarios, an anti-virus/anti-malware scanner API
                        // is used on the file before making the file available
                        // for download or for use by other systems. 
                        // For more information, see the topic that accompanies 
                        // this sample.

                        AppFile file = new AppFile()
                        {
                            Content = formFileContent,
                            UntrustedName = formFile.FileName,
                            Size = formFile.Length,
                            UploadDT = DateTime.UtcNow
                        };
                        file.Id = WebUtility.HtmlEncode(formFile.FileName);

                        // Convert to a landscape or system object
                        byte[] bytes = file.Content;
                        string bitString = Encoding.ASCII.GetString(bytes);
                        string jsonString = Helper.TfvarToJson(bitString);
                        if (file.Id.EndsWith("INFRASTRUCTURE.tfvars"))
                        {
                            LandscapeModel landscape = JsonSerializer.Deserialize<LandscapeModel>(jsonString);
                            landscape.Id = (landscape.environment + "-" + Helper.MapRegion(landscape.location) + "-" + landscape.network_logical_name + "-infrastructure").ToUpper();
                            await _landscapeService.CreateAsync(landscape);
                        }
                        else
                        {
                            SystemModel system = JsonSerializer.Deserialize<SystemModel>(jsonString);
                            system.Id = (system.environment + "-" + Helper.MapRegion(system.location) + "-" + system.network_logical_name + "-" + system.sid).ToUpper();
                            await _systemService.CreateAsync(system);
                        }

                        await _appFileService.CreateAsync(file);

                        TempData["success"] = "Successfully uploaded file(s)";
                    }
                }
                catch
                {
                    TempData["error"] = "Error uploading files. Common errors include duplicate file names, existing landscapes / systems, and invalid content";
                }
                return RedirectToAction("Index");
            }

            return View();
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id)
        {
            AppFile file = await _appFileService.GetByIdAsync(id);
            byte[] bytes = file.Content;
            string bitString = Encoding.ASCII.GetString(bytes);
            ViewBag.Message = bitString;
            return View(file);
        }

        [ActionName("Delete")]
        public async Task<IActionResult> DeleteAsync(string id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            AppFile file = await _appFileService.GetByIdAsync(id);
            if (file == null)
            {
                return NotFound();
            }
            byte[] bytes = file.Content;
            string bitString = Encoding.ASCII.GetString(bytes);
            ViewBag.Message = bitString;
            return View(file);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmedAsync(string id)
        {
            await _appFileService.DeleteAsync(id);
            TempData["success"] = "Successfully deleted file " + id;
            return RedirectToAction("Index");
        }
    }
}
