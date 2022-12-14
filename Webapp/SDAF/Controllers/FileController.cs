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
using Microsoft.Net.Http.Headers;
using Newtonsoft.Json;
using JsonSerializer = System.Text.Json.JsonSerializer;

namespace AutomationForm.Controllers
{
    public class FileController : Controller
    {
        private readonly ITableStorageService<AppFile> _appFileService;
        private readonly ITableStorageService<LandscapeEntity> _landscapeService;
        private readonly ITableStorageService<SystemEntity> _systemService;
        private readonly RestHelper restHelper;

        public FileController(ITableStorageService<AppFile> appFileService, ITableStorageService<LandscapeEntity> landscapeService,
            ITableStorageService<SystemEntity> systemService, IConfiguration configuration)
        {
            _appFileService = appFileService;
            _landscapeService = landscapeService;
            _systemService = systemService;
            restHelper = new RestHelper(configuration);
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            return View(await _appFileService.GetAllAsync());
        }

        [ActionName("Templates")]
        public ActionResult Templates(string sourceController)
        {
            string[] landscapeFilePaths = restHelper.GetTemplateFileNames("Terraform/WORKSPACES/LANDSCAPE").Result;
            string[] systemFilePaths = restHelper.GetTemplateFileNames("Terraform/WORKSPACES/SYSTEM").Result;

            Dictionary<string, string[]> filePaths = new Dictionary<string, string[]>
            {
                { "landscapes", landscapeFilePaths },
                { "systems", systemFilePaths }
            };
            ViewBag.SourceController = sourceController;
            return View(filePaths);
        }

        [ActionName("UseTemplate")]
        public IActionResult UseTemplate(string fileName, string sourceController)
        {
            string content = restHelper.GetTemplateFile(fileName).Result;
            ViewBag.Message = content;
            ViewBag.TemplateName = fileName.Substring(fileName.LastIndexOf('/') + 1);
            ViewBag.SourceController = sourceController;
            return View("Create");
        }

        [ActionName("Upload")]
        public IActionResult UploadAsync(string sourceController)
        {
            ViewBag.SourceController = sourceController;
            return View();
        }

        [HttpPost]
        [ActionName("Upload")]
        public async Task<IActionResult> UploadAsync(FileUploadModel fileUpload, string sourceController)
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
                            ViewBag.SourceController = sourceController;
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
                return RedirectToAction("Index", sourceController);
            }
            ViewBag.SourceController = sourceController;
            return View();
        }


        [ActionName("Convert")]
        public async Task<IActionResult> ConvertFileToObject(string id, string sourceController)
        {
            try
            {
                // Convert a file to a landscape or system object
                AppFile file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
                if (file == null) return NotFound();

                id = id.Substring(0, id.IndexOf('.'));
                byte[] bytes = file.Content;
                string bitString = Encoding.UTF8.GetString(bytes);
                string jsonString = Helper.TfvarToJson(bitString);
                if (file.Id.EndsWith("INFRASTRUCTURE.tfvars"))
                {
                    LandscapeModel landscape = JsonSerializer.Deserialize<LandscapeModel>(jsonString);
                    landscape.Id = id;
                    await _landscapeService.CreateAsync(new LandscapeEntity(landscape));
                    TempData["success"] = "Successfully converted file " + id + " to a workload zone object";
                }
                else
                {
                    SystemModel system = JsonSerializer.Deserialize<SystemModel>(jsonString);
                    system.Id = id;
                    await _systemService.CreateAsync(new SystemEntity(system));
                    TempData["success"] = "Successfully converted file " + id + " to a system object";
                }
            }
            catch (Exception e)
            {
                TempData["error"] = "Error converting file: " + e.Message;
            }
            return RedirectToAction("Index", sourceController);
        }

        [ActionName("Details")]
        public async Task<IActionResult> DetailsAsync(string id, string sourceController)
        {
            AppFile file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
            if (file == null) return NotFound();

            byte[] bytes = file.Content;
            string bitString = Encoding.UTF8.GetString(bytes);
            ViewBag.Message = bitString;
            ViewBag.SourceController = sourceController;
            return View(file);
        }

        [ActionName("Create")]
        public IActionResult Create(string sourceController)
        {
            ViewBag.SourceController = sourceController;
            return View();
        }

        [HttpPost]
        [ActionName("Create")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateAsync(string id, string fileContent, string templateName, string sourceController)
        {
            try
            {
                byte[] bytes = Encoding.UTF8.GetBytes(fileContent);

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
                
                return RedirectToAction("Index", sourceController);
            }
            catch (Exception e)
            {
                ModelState.AddModelError("FileId", "Error creating file: " + e.Message);
            }

            ViewBag.TemplateName = templateName;
            ViewBag.Message = fileContent;
            ViewBag.SourceController = sourceController;
            return View();

        }
        
        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id, string sourceController, bool isImagesFile=false)
        {
            AppFile file = (isImagesFile) ? await GetImagesFile() : await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
            if (file == null) return NotFound();

            byte[] bytes = file.Content;
            string bitString = Encoding.UTF8.GetString(bytes);
            ViewBag.Message = bitString;
            ViewBag.SourceController = sourceController;
            ViewBag.IsImagesFile = isImagesFile;
            return View(file);
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditAsync(string id, string newId, string fileContent, string sourceController, bool isImagesFile=false)
        {
            AppFile file = (isImagesFile) ? await GetImagesFile() : await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
            if (file == null) return NotFound();
            try
            {
                byte[] bytes = Encoding.UTF8.GetBytes(fileContent);
                file.Content = bytes;
                if (id != newId)
                {
                    file.Id = newId;
                    await _appFileService.CreateAsync(file);
                    await _appFileService.DeleteAsync(id, GetPartitionKey(id));
                }
                else
                {
                    await _appFileService.UpdateAsync(file);
                }

                TempData["success"] = "Successfully updated file " + id;

                return RedirectToAction("Index", sourceController);
            }
            catch (Exception e)
            {
                ModelState.AddModelError("FileId", "Error updating file: " + e.Message);
            }
            ViewBag.Message = fileContent;
            ViewBag.SourceController = sourceController;
            ViewBag.IsImagesFile = isImagesFile;
            return View(file);

        }

        [HttpPost]
        [ActionName("SubmitNew")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitNewAsync(string id, string newId, string fileContent, string sourceController)
        {
            AppFile file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
            if (file == null) return NotFound();
            
            file.Id = newId;
            byte[] bytes = Encoding.UTF8.GetBytes(fileContent);
            file.Content = bytes;

            try
            {
                await _appFileService.CreateAsync(file);

                TempData["success"] = "Successfully created file " + id;
                
                return RedirectToAction("Index", sourceController);
            }
            catch (Exception e)
            {
                ModelState.AddModelError("FileId", "Error creating file: " + e.Message);
            }

            ViewBag.Message = fileContent;
            ViewBag.SourceController = sourceController;
            return View("Edit", file);
        }

        [ActionName("Delete")]
        public async Task<IActionResult> DeleteAsync(string id, string sourceController)
        {
            if (id == null)
            {
                return BadRequest();
            }

            AppFile file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
            if (file == null)
            {
                return NotFound();
            }
            byte[] bytes = file.Content;
            string bitString = Encoding.UTF8.GetString(bytes);
            ViewBag.Message = bitString;
            ViewBag.SourceController = sourceController;
            return View(file);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmedAsync(string id, string sourceController)
        {
            await _appFileService.DeleteAsync(id, GetPartitionKey(id));
            TempData["success"] = "Successfully deleted file " + id;
            return RedirectToAction("Index", sourceController);
        }

        [ActionName("Download")]
        public async Task<ActionResult> DownloadFile(string id, string sourceController, bool isImagesFile=false)
        {
            try
            {
                AppFile file = (isImagesFile) ? await GetImagesFile() : await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
                if (file == null) return NotFound();

                var stream = new MemoryStream(file.Content);
                return new FileStreamResult(stream, new MediaTypeHeaderValue("text/plain"))
                {
                    FileDownloadName = id
                };
            }
            catch (Exception e)
            {
                TempData["error"] = "Something went wrong downloading file " + id + ": " + e.Message;
                return RedirectToAction("Index", sourceController);
            }
        }

        private string GetPartitionKey(string id)
        {
            return id.Substring(0, id.IndexOf('-'));
        }

        public async Task<AppFile> GetImagesFile()
        {
            string filename = "VM-Images.json";
            string partitionKey = "VM";
            AppFile file = null;
            try
            {
                file = await _appFileService.GetByIdAsync(filename, partitionKey);
            }
            catch
            {
                byte[] byteContent = System.IO.File.ReadAllBytes("ParameterDetails/" + filename);

                using (MemoryStream memory = new MemoryStream(byteContent))
                {
                    file = new AppFile()
                    {
                        Id = WebUtility.HtmlEncode(filename),
                        Content = byteContent,
                        UntrustedName = filename,
                        Size = memory.Length,
                        UploadDT = DateTime.UtcNow
                    };
                }
            }
            return file ?? new AppFile();
        }
    }
}