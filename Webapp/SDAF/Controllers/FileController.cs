// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using SDAFWebApp.Models;
using SDAFWebApp.Services;
using SDAFWebApp.Controllers;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.IO;
using Microsoft.AspNetCore.Http;
using Microsoft.Net.Http.Headers;
using JsonSerializer = System.Text.Json.JsonSerializer;
using Microsoft.Extensions.Logging;

namespace SDAFWebApp.Controllers
{
    public class FileController(ITableStorageService<AppFile> appFileService, ITableStorageService<LandscapeEntity> landscapeService,
        ITableStorageService<SystemEntity> systemService, RestHelper restHelper, ILogger<FileController> logger) : Controller
    {
        private readonly ITableStorageService<AppFile> _appFileService = appFileService;
        private readonly ITableStorageService<LandscapeEntity> _landscapeService = landscapeService;
        private readonly ITableStorageService<SystemEntity> _systemService = systemService;
        private readonly RestHelper restHelper = restHelper;
        private readonly ILogger<FileController> _logger = logger;

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            return View(await _appFileService.GetAllAsync());
        }

        [ActionName("Templates")]
        public async Task<ActionResult> Templates(string sourceController)
        {
            try
            {
                string[] landscapeFilePaths = await restHelper.GetTemplateFileNames("Terraform/WORKSPACES/LANDSCAPE");
                string[] systemFilePaths = await restHelper.GetTemplateFileNames("Terraform/WORKSPACES/SYSTEM");

                Dictionary<string, string[]> filePaths = new()
            {
                { "landscapes", landscapeFilePaths },
                { "systems", systemFilePaths }
            };
                ViewBag.SourceController = sourceController;
                return View(filePaths);
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to retrieve repository templates");
                TempData["error"] = "Templates could not be retrieved.";
            }
            return RedirectToAction("Index");


        }

        [ActionName("UseTemplate")]
        public async Task<IActionResult> UseTemplate(string fileName, string sourceController)
        {
            string content = await restHelper.GetTemplateFile(fileName);
            ViewBag.Message = content;
            ViewBag.TemplateName = fileName[(fileName.LastIndexOf('/') + 1)..];
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
        [ValidateAntiForgeryToken]
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

                        AppFile file = new()
                        {
                            Content = formFileContent,
                            UntrustedName = formFile.FileName,
                            Size = formFile.Length,
                            UploadDT = DateTime.UtcNow,
                            Id = IdentifierParser.ParseAppFile(formFile.FileName).FileName
                        };

                        await _appFileService.CreateAsync(file);

                        TempData["success"] = "Successfully uploaded file(s)";
                    }
                }
                catch (ArgumentException e)
                {
                    _logger.LogWarning(e, "Rejected uploaded file with an invalid identifier");
                    ModelState.AddModelError("FormFiles", "The uploaded filename is invalid.");
                    ViewBag.SourceController = sourceController;
                    return View();
                }
                catch (Exception e)
                {
                    _logger.LogError(e, "Failed to upload app files");
                    TempData["error"] = "The files could not be uploaded.";
                }
                return RedirectToAction("Index", sourceController);
            }
            ViewBag.SourceController = sourceController;
            return View();
        }


        [HttpPost]
        [ActionName("Convert")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ConvertFileToObject(string id, string sourceController)
        {
            sourceController = string.IsNullOrWhiteSpace(sourceController) ? "File" : sourceController;
            try
            {
                // Convert a file to a landscape or system object
                AppFile file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
                if (file == null) return NotFound();

                AppFileIdentifier parsedFile = IdentifierParser.ParseAppFile(id);
                id = parsedFile.ObjectId;
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
            catch (ArgumentException e)
            {
                _logger.LogWarning(e, "Rejected invalid file identifier");
                ModelState.AddModelError("id", "The file identifier is invalid.");
                TempData["error"] = "The selected file identifier is invalid.";
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to convert app file");
                TempData["error"] = "The file could not be converted.";
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
            if (!IdentifierParser.TryParseAppFile(id, out AppFileIdentifier parsedId, out string validationError))
            {
                ModelState.AddModelError("id", validationError);
                ViewBag.TemplateName = templateName;
                ViewBag.Message = fileContent;
                ViewBag.SourceController = sourceController;
                return View();
            }

            try
            {
                byte[] bytes = Encoding.UTF8.GetBytes(fileContent);

                AppFile file = new()
                {
                    Id = parsedId.FileName,
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
                _logger.LogError(e, "Failed to create app file of kind {FileKind}", parsedId.Kind);
                ModelState.AddModelError("id", "The file could not be created.");
            }

            ViewBag.TemplateName = templateName;
            ViewBag.Message = fileContent;
            ViewBag.SourceController = sourceController;
            return View();

        }

        [ActionName("Edit")]
        public async Task<IActionResult> EditAsync(string id, string sourceController, string fileName, int type = 0)
        {
            AppFile file = null;
            ViewBag.IsImagesFile = false;
            switch (type)
            {
                case 0:
                    file = await GetImagesFile(fileName, type, "VM");
                    ViewBag.IsImagesFile = true;
                    file.FileType = 0;
                    break;
                case 1:
                case 2:
                    file = await GetImagesFile(id + "_" + fileName, type, IdentifierParser.ParseSystem(id).PartitionKey);
                    ViewBag.IsImagesFile = true;
                    ViewBag.FilePattern = id + "_" + fileName;
                    file.FileType = type;
                    break;
                default:
                    file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
                    break;
            }

            if (file == null) return NotFound();

            byte[] bytes = file.Content;
            string bitString = Encoding.UTF8.GetString(bytes);
            ViewBag.Message = bitString;
            ViewBag.SourceController = sourceController;
            ViewBag.Type = type;
            return View(file);
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditAsync(string id, string newId, string fileContent, string sourceController, int type)
        {
            if (!IdentifierParser.TryParseAppFile(id, out AppFileIdentifier oldIdentifier, out string oldError))
            {
                return BadRequest(new { field = "id", error = oldError });
            }
            if (!IdentifierParser.TryParseAppFile(newId, out AppFileIdentifier newIdentifier, out string newError))
            {
                ModelState.AddModelError("newId", newError);
                ViewBag.Message = fileContent;
                ViewBag.SourceController = sourceController;
                ViewBag.Type = type;
                return View(new AppFile { Id = id, Content = Encoding.UTF8.GetBytes(fileContent ?? string.Empty) });
            }

            AppFile file = null;
            ViewBag.IsImagesFile = false;
            int newType = type;

            if (newId.EndsWith("_custom_naming.json"))
            {
                newType = 2;

            }
            else if (newId.EndsWith("_custom_sizes.json"))
            {
                newType = 1;

            }


            switch (newType)
            {
                case 0:
                    file = await GetImagesFile(newId, newType, "VM");
                    ViewBag.IsImagesFile = true;
                    break;
                case 1:
                case 2:
                    file = await GetImagesFile(newId, newType, GetPartitionKey(id));
                    ViewBag.IsImagesFile = true;
                    ViewBag.FilePattern = newId;
                    break;
                default:
                    file = await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
                    break;
            }
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
                if (newType == 0)
                {
                    return RedirectToAction("Index", sourceController);
                }
                else
                {
                    return RedirectToAction("Edit", sourceController, new
                    {
                        @id = newIdentifier.ObjectId,
                        @partitionKey = newIdentifier.PartitionKey
                    });
                }
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to update app file of kind {FileKind}", newIdentifier.Kind);
                ModelState.AddModelError("newId", "The file could not be updated.");
            }
            ViewBag.Message = fileContent;
            ViewBag.SourceController = sourceController;
            ViewBag.Type = type;

            return View(file);

        }

        [HttpPost]
        [ActionName("SubmitNew")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SubmitNewAsync(string id, string newId, string fileContent, string sourceController)
        {
            if (!IdentifierParser.TryParseAppFile(id, out AppFileIdentifier existingIdentifier, out string existingError))
            {
                return BadRequest(new { field = "id", error = existingError });
            }
            if (!IdentifierParser.TryParseAppFile(newId, out AppFileIdentifier newIdentifier, out string newError))
            {
                ModelState.AddModelError("newId", newError);
                return View("Edit", new AppFile { Id = id, Content = Encoding.UTF8.GetBytes(fileContent ?? string.Empty) });
            }

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
                _logger.LogError(e, "Failed to create a copy of app file kind {FileKind}", newIdentifier.Kind);
                ModelState.AddModelError("newId", "The file could not be created.");
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
        public async Task<ActionResult> DownloadFile(string id, string sourceController, string fileName, bool isImagesFile = false)
        {
            try
            {
                AppFile file = (isImagesFile) ? await GetImagesFile(fileName, 0, GetPartitionKey(id)) : await _appFileService.GetByIdAsync(id, GetPartitionKey(id));
                if (file == null) return NotFound();

                // FileStreamResult takes ownership of the stream and disposes it after writing the response.
                var stream = new MemoryStream(file.Content);
                return new FileStreamResult(stream, new MediaTypeHeaderValue("text/plain"))
                {
                    FileDownloadName = id
                };
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to download app file");
                TempData["error"] = "The file could not be downloaded.";
                return RedirectToAction("Index", sourceController);
            }
        }

        private static string GetPartitionKey(string id)
        {
            return IdentifierParser.ParseAppFile(id).PartitionKey;
        }

        private async Task<AppFile> GetImagesFile(string filename, int type, string partitionKey)
        {
            try
            {
                AppFile file = await _appFileService.GetByIdAsync(filename, partitionKey);
                return file ?? LoadFallbackFile(filename, type);
            }
            catch (RepositoryOperationException ex) when (ex.ErrorCategory == RepositoryErrorCategory.NotFound)
            {
                _logger.LogInformation(ex, "Images configuration was not found; using packaged fallback for type {FileType}", type);
                return LoadFallbackFile(filename, type);
            }
        }

        private static AppFile LoadFallbackFile(string filename, int type)
        {
            string newName = filename;

            if (filename.EndsWith("_custom_sizes.json", StringComparison.OrdinalIgnoreCase))
            {
                newName = "custom_sizes.json";
                type = 1;
            }
            if (filename.EndsWith("_custom_naming.json", StringComparison.OrdinalIgnoreCase))
            {
                newName = "custom_naming.json";
                type = 2;
            }

            if (!string.Equals(Path.GetFileName(newName), newName, StringComparison.Ordinal) ||
                newName.Contains("..", StringComparison.Ordinal))
            {
                throw new ArgumentException("Invalid fallback file name.", nameof(filename));
            }

            byte[] byteContent = System.IO.File.ReadAllBytes(
                Path.Combine("ParameterDetails", newName));

            return new AppFile
            {
                Id = filename,
                Content = byteContent,
                UntrustedName = filename,
                Size = byteContent.LongLength,
                UploadDT = DateTime.UtcNow,
                FileType = type
            };
        }
    }
}
