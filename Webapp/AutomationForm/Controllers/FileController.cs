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
using System.IO;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;

namespace AutomationForm.Controllers
{
    public class FileController : Controller
    {
        private readonly ILandscapeService<AppFile> _appFileService;
        private readonly ILandscapeService<LandscapeModel> _landscapeService;
        private readonly ILandscapeService<SystemModel> _systemService;
        private readonly RestHelper restHelper;

        public FileController(ILandscapeService<AppFile> appFileService, ILandscapeService<LandscapeModel> landscapeService, ILandscapeService<SystemModel> systemService, IConfiguration configuration)
        {
            _appFileService = appFileService;
            _landscapeService = landscapeService;
            _systemService = systemService;
            restHelper = new RestHelper(configuration);
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            return View(await _appFileService.GetNAsync(10));
        }

        [ActionName("Templates")]
        public ActionResult Templates()
        {
            string[] landscapeFilePaths = restHelper.GetTemplateFileNames("samples/WORKSPACES/LANDSCAPE").Result;
            string[] systemFilePaths = restHelper.GetTemplateFileNames("samples/WORKSPACES/SYSTEM/").Result;

            Dictionary<string, string[]> filePaths = new Dictionary<string, string[]>
            {
                { "landscapes", landscapeFilePaths },
                { "systems", systemFilePaths }
            };
            
            return View(filePaths);
        }

        [ActionName("UseTemplate")]
        public IActionResult UseTemplate(string fileName)
        {
            string content = restHelper.GetTemplateFile(fileName).Result;
            ViewBag.Message = content;
            ViewBag.TemplateName = fileName.Substring(fileName.LastIndexOf('/') + 1);
            return View("Create");
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

                        await _appFileService.CreateAsync(file);

                        TempData["success"] = "Successfully uploaded file(s)";
                    }
                }
                catch (Exception e)
                {
                    TempData["error"] = "Error uploading files: " + e.Message;
                }
                return RedirectToAction("Index");
            }

            return View();
        }


        [ActionName("Convert")]
        public async Task<IActionResult> ConvertFileToObject(string id)
        {
            try
            {
                // Convert a file to a landscape or system object
                AppFile file = await _appFileService.GetByIdAsync(id);
                if (file == null) return NotFound();

                id = id.Substring(0, id.IndexOf('.'));
                byte[] bytes = file.Content;
                string bitString = Encoding.ASCII.GetString(bytes);
                string jsonString = Helper.TfvarToJson(bitString);
                if (file.Id.EndsWith("INFRASTRUCTURE.tfvars"))
                {
                    LandscapeModel landscape = JsonSerializer.Deserialize<LandscapeModel>(jsonString);
                    landscape.Id = id;
                    await _landscapeService.CreateAsync(landscape);
                    TempData["success"] = "Successfully converted file " + id + " to a landscape object";
                }
                else
                {
                    SystemModel system = JsonSerializer.Deserialize<SystemModel>(jsonString);
                    system.Id = id;
                    await _systemService.CreateAsync(system);
                    TempData["success"] = "Successfully converted file " + id + " to a system object";
                }
            }
            catch (Exception e)
            {
                TempData["error"] = "Error converting file: " + e.Message;
            }
            return RedirectToAction("Index");
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id)
        {
            AppFile file = await _appFileService.GetByIdAsync(id);
            if (file == null) return NotFound();

            byte[] bytes = file.Content;
            string bitString = Encoding.ASCII.GetString(bytes);
            ViewBag.Message = bitString;
            return View(file);
        }

        [ActionName("Create")]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        [ActionName("Create")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateAsync(string id, string fileContent, string templateName)
        {
            try
            {
                byte[] bytes = Encoding.ASCII.GetBytes(fileContent);

                AppFile file = new AppFile()
                {
                    Id = WebUtility.HtmlEncode(id),
                    Content = bytes,
                    UntrustedName = id,
                    Size = bytes.Length,
                    UploadDT = DateTime.UtcNow
                };

                await _appFileService.CreateAsync(file);

                TempData["success"] = "Successfully created file " + id;
                
                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                ModelState.AddModelError("FileId", "Error creating file: " + e.Message);
            }

            ViewBag.TemplateName = templateName;
            ViewBag.Message = fileContent;
            return View();

        }
        
        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id)
        {
            AppFile file = await _appFileService.GetByIdAsync(id);
            if (file == null) return NotFound();

            byte[] bytes = file.Content;
            string bitString = Encoding.ASCII.GetString(bytes);
            ViewBag.Message = bitString;
            return View(file);
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditAsync(string id, string newId, string fileContent)
        {
            AppFile file = await _appFileService.GetByIdAsync(id);
            if (file == null) return NotFound();
            try
            {
                if (id != newId)
                {
                    file.Id = newId;
                    await _appFileService.CreateAsync(file);
                    await _appFileService.DeleteAsync(id);
                }
                else
                {
                    byte[] bytes = Encoding.ASCII.GetBytes(fileContent);
                    file.Content = bytes;
                    await _appFileService.UpdateAsync(file);
                }

                TempData["success"] = "Successfully updated file " + id;

                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                ModelState.AddModelError("FileId", "Error updating file: " + e.Message);
            }
            ViewBag.Message = fileContent;
            return View(file);

        }

        [HttpPost]
        [ActionName("SubmitNew")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitNewAsync(string id, string newId, string fileContent)
        {
            AppFile file = await _appFileService.GetByIdAsync(id);
            if (file == null) return NotFound();
            
            file.Id = newId;
            byte[] bytes = Encoding.ASCII.GetBytes(fileContent);
            file.Content = bytes;

            try
            {
                await _appFileService.CreateAsync(file);

                TempData["success"] = "Successfully created file " + id;
                
                return RedirectToAction("Index");
            }
            catch (Exception e)
            {
                ModelState.AddModelError("FileId", "Error creating file: " + e.Message);
            }

            ViewBag.Message = fileContent;
            return View("Edit", file);
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