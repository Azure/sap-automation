using AutomationForm.Models;
using AutomationForm.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace AutomationForm.Controllers
{
  public class Helper : Controller
  {
    public static readonly Dictionary<string, string> regionMapping = new()
            {
                {"australiacentral", "auce"},
                {"australiacentral2", "auc2"},
                {"australiaeast", "auea"},
                {"australiasoutheast", "ause"},
                {"brazilsouth", "brso"},
                {"brazilsoutheast", "brse"},
                {"brazilus", "brus"},
                {"canadacentral", "cace"},
                {"canadaeast", "caea"},
                {"centralindia", "cein"},
                {"centralus", "ceus"},
                {"centraluseuap", "ceua"},
                {"eastasia", "eaas"},
                {"eastus", "eaus"},
                {"eastus2", "eus2"},
                {"eastus2euap", "eusa"},
                {"eastusstg", "eusg"},
                {"francecentral", "frce"},
                {"francesouth", "frso"},
                {"germanynorth", "geno"},
                {"germanywestcentral", "gewc"},
                {"japaneast", "jaea"},
                {"japanwest", "jawe"},
                {"jioindiacentral", "jinc"},
                {"jioindiawest", "jinw"},
                {"koreacentral", "koce"},
                {"koreasouth", "koso"},
                {"northcentralus", "ncus"},
                {"northeurope", "noeu"},
                {"norwayeast", "noea"},
                {"norwaywest", "nowe"},
                {"qatarcentral", "qace"},
                {"southafricanorth", "sano"},
                {"southafricawest", "sawe"},
                {"southcentralus", "scus"},
                {"southcentralusstg", "scug"},
                {"southeastasia", "soea"},
                {"southindia", "soin"},
                {"swedencentral", "sece"},
                {"swedensouth", "seso"},
                {"switzerlandnorth", "swno"},
                {"switzerlandwest", "swwe"},
                {"uaecentral", "uace"},
                {"uaenorth", "uano"},
                {"uksouth", "ukso"},
                {"ukwest", "ukwe"},
                {"westcentralus", "wcus"},
                {"westeurope", "weeu"},
                {"westindia", "wein"},
                {"westus", "weus"},
                {"westus2", "wus2"},
                {"westus3", "wus3"}
            };
    public static string ConvertToTerraform<T>(T model)
    {
      string modelType = (model.GetType() == typeof(LandscapeModel)) ? "Landscape" : "System";
      string path = $"ParameterDetails/{modelType}Template.txt";

      if (!System.IO.File.Exists(path))
      {
        return $"Error generating terraform variables file: No template file {path} was found";
      }

      StringBuilder stringBuilder = new();

      foreach (string line in System.IO.File.ReadLines(path))
      {
        string lineToAdd = line;
        Regex paramRegex = new(@"\$\$\w*\$\$");

        if (paramRegex.IsMatch(line))
        {
          string parameter = paramRegex.Match(line).Value.Trim('$');
          PropertyInfo property = model.GetType().GetProperty(parameter);
          if (property == null)
          {
            lineToAdd = "#" + parameter + " = null";
          }
          else
          {
            lineToAdd = WriteTfLine(property, model);
          }
        }
        stringBuilder.AppendLine(lineToAdd);
      }

      return stringBuilder.ToString();
    }
    // Create the text that sets a model property to its value for a tfvars file
    public static string WriteTfLine<T>(PropertyInfo property, T model)
    {
      StringBuilder str = new();
      var value = property.GetValue(model);
      if (property.PropertyType.GetElementType() == typeof(Tag))
      {
        if (value == null) return "#" + property.Name + " = {}";
        str.AppendLine(property.Name + " = {");
        foreach (Tag t in (Tag[])value)
        {
          if (t.Key != null && t.Key.Length > 0)
          {
            str.AppendLine($"  \"{t.Key}\" = \"{t.Value}\",");
          }
        }
        str.Append("}");
      }
      else if (property.PropertyType.IsArray)
      {
        if (value == null) return "#" + property.Name + " = []";
        str.Append(property.Name + " = [");
        foreach (var val in (string[])value)
        {
          str.Append($"\"{val}\", ");
        }
        str.Remove(str.Length - 2, 2);
        str.Append("]");
      }
      else if (property.PropertyType == typeof(Image))
      {
        if (value == null) return "#" + property.Name + " = {}";
        Image img = (Image)value;
        if (img.IsInitialized)
        {
          str.AppendLine(property.Name + " = {");
          str.AppendLine("  os_type = " + $"\"{img.os_type}\",");
          str.AppendLine("  source_image_id = " + $"\"{img.source_image_id}\",");
          str.AppendLine("  publisher = " + $"\"{img.publisher}\",");
          str.AppendLine("  offer = " + $"\"{img.offer}\",");
          str.AppendLine("  sku = " + $"\"{img.sku}\",");
          str.AppendLine("  version = " + $"\"{img.version}\",");
          str.AppendLine("  type = " + $"\"{img.type}\"");
          str.Append("}");
        }
        else
        {
          return "#" + property.Name + " = {}";
        }
      }
      else if (property.PropertyType == typeof(bool?))
      {
        if (value == null) return "#" + property.Name + " = false";
        bool b = (bool)value;
        str.Append(property.Name + " = " + b.ToString().ToLower());
      }
      else if (property.PropertyType == typeof(int?))
      {
        if (value == null) return "#" + property.Name + " = 0";
        int i = (int)value;
        str.Append(property.Name + " = " + i);
      }
      else
      {
        if (value == null) return "#" + property.Name + " = \"\"";
        str.Append(property.Name + " = " + $"\"{value}\"");
      }

      return str.ToString();
    }
    public static StringContent CreateHttpContent(string changeType, string path, string content, GitRequestBody requestBody)
    {
      Commit commit = new()
      {
        comment = $"{changeType}ed {path}",
        changes = new Change[]
          {
                    new Change()
                    {
                        changeType = changeType,
                        item = new Item()
                        {
                            path = path,
                        },
                        newContent = new Newcontent()
                        {
                            content = content,
                            contentType = "rawtext"
                        }
                    }
          }
      };
      requestBody.commits = new Commit[] { commit };
      string requestJson = JsonSerializer.Serialize(requestBody);
      return new StringContent(requestJson, Encoding.ASCII, "application/json");
    }
    public static T ReadJson<T>(string filename)
    {
      if (System.IO.File.Exists(filename))
      {
        string jsonString = System.IO.File.ReadAllText(filename);
        T deserializedObj = JsonSerializer.Deserialize<T>(jsonString);

        return deserializedObj;
      }
      else
      {
        throw new DirectoryNotFoundException();
      }
    }
    public static string GenerateId<T>(T model)
    {
      string id;
      if (model.GetType() == typeof(LandscapeModel))
      {
        LandscapeModel landscape = (LandscapeModel)Convert.ChangeType(model, typeof(LandscapeModel));
        id = (landscape.environment + "-" + MapRegion(landscape.location) + "-" + landscape.network_logical_name + "-infrastructure").ToUpper();
      }
      else if (model.GetType() == typeof(SystemModel))
      {
        SystemModel system = (SystemModel)Convert.ChangeType(model, typeof(SystemModel));
        id = (system.environment + "-" + MapRegion(system.location) + "-" + system.network_logical_name + "-" + system.sid).ToUpper();
      }
      else
      {
        throw new Exception("Object provided is neither a system nor a workload zone");
      }
      return id;
    }
    public static string MapRegion(string region)
    {
      if (region == null) return "";
      if (regionMapping.ContainsKey(region))
      {
        return regionMapping[region];
      }
      else
      {
        throw new KeyNotFoundException("location is not a valid Azure region");
      }
    }
    public static async Task<byte[]> ProcessFormFile(IFormFile formFile,
        ModelStateDictionary modelState, string[] permittedExtensions,
        long sizeLimit)
    {
      var fieldDisplayName = "";

      // Use reflection to obtain the display name for the model
      // property associated with this IFormFile. If a display
      // name isn't found, error messages simply won't show
      // a display name.
      MemberInfo property =
          typeof(FileUploadModel).GetProperty(
              formFile.Name[(formFile.Name.IndexOf(".", StringComparison.Ordinal) + 1)..]);

      if (property != null)
      {
        if (property.GetCustomAttribute(typeof(DisplayAttribute)) is DisplayAttribute displayAttribute)
        {
          fieldDisplayName = $"{displayAttribute.Name} ";
        }
      }

      // Don't trust the file name sent by the client. To display
      // the file name, HTML-encode the value.
      var trustedFileNameForDisplay = WebUtility.HtmlEncode(formFile.FileName);

      // Check the file length. This check doesn't catch files that only have
      // a BOM as their content.
      if (formFile.Length == 0)
      {
        modelState.AddModelError(formFile.Name,
            $"{fieldDisplayName}({trustedFileNameForDisplay}) is empty.");

        return Array.Empty<byte>();
      }

      if (formFile.Length > sizeLimit)
      {
        var megabyteSizeLimit = sizeLimit / 1048576;
        modelState.AddModelError(formFile.Name,
            $"{fieldDisplayName}({trustedFileNameForDisplay}) exceeds " +
            $"{megabyteSizeLimit:N1} MB.");

        return Array.Empty<byte>();
      }
      Regex rx = new(@"^\w{0,5}-\w{4}-\w{0,7}-\w{0,15}\.tfvars$");
      if (!rx.IsMatch(formFile.FileName))
      {
        modelState.AddModelError(formFile.Name,
            $"{fieldDisplayName}({trustedFileNameForDisplay}) is named incorrectly");

        return Array.Empty<byte>();
      }

      try
      {
        using var memoryStream = new MemoryStream();
        await formFile.CopyToAsync(memoryStream);

        // Check the content length in case the file's only
        // content was a BOM and the content is actually
        // empty after removing the BOM.
        if (memoryStream.Length == 0)
        {
          modelState.AddModelError(formFile.Name,
              $"{fieldDisplayName}({trustedFileNameForDisplay}) is empty.");
        }

        if (!IsValidFileExtension(formFile.FileName, memoryStream, permittedExtensions))
        {
          modelState.AddModelError(formFile.Name,
              $"{fieldDisplayName}({trustedFileNameForDisplay}) file type isn't permitted.");
        }
        else
        {
          return memoryStream.ToArray();
        }
      }
      catch (Exception ex)
      {
        modelState.AddModelError(formFile.Name,
            $"{fieldDisplayName}({trustedFileNameForDisplay}) upload failed. " +
            $"Please contact the Help Desk for support. Error: {ex.HResult}");
      }

      return Array.Empty<byte>();
    }

    private static bool IsValidFileExtension(string fileName, Stream data, string[] permittedExtensions)
    {
      if (string.IsNullOrEmpty(fileName) || data == null || data.Length == 0)
      {
        return false;
      }

      var ext = Path.GetExtension(fileName).ToLowerInvariant();

      if (string.IsNullOrEmpty(ext) || !permittedExtensions.Contains(ext))
      {
        return false;
      }

      return true;
    }

    public static string TfvarToJson(string hclString)
    {
      StringReader stringReader = new(hclString);
      StringBuilder jsonString = new();
      jsonString.AppendLine("{");
      while (true)
      {
        string currLine = stringReader.ReadLine();
        if (currLine == null)
        {
          jsonString.Remove(jsonString.Length - 3, 1);
          jsonString.AppendLine("}");
          break;
        }
        else if (currLine.StartsWith("#") || currLine == "")
        {
          continue;
        }
        else if (currLine.StartsWith("}"))
        {
          jsonString.Remove(jsonString.Length - 3, 1);
          jsonString.AppendLine("},");
        }
        else
        {
          int equalIndex = currLine.IndexOf("=");
          if (equalIndex >= 0)
          {
            string key = currLine[..equalIndex].Trim();
            if (!key.StartsWith("\""))
            {
              key = "\"" + key + "\"";
            }
            string value = null;
            Console.WriteLine(key);
            if (key.EndsWith("tags\""))
            {
              value += "[";
              currLine = stringReader.ReadLine();
              while (!currLine.StartsWith("}"))
              {
                equalIndex = currLine.IndexOf("=");
                var tagKey = currLine[..equalIndex].Trim();
                if (!tagKey.StartsWith("\""))
                {
                  tagKey = "\"" + tagKey + "\"";
                }
                var tagValue = currLine[(equalIndex + 1)..].Trim();
                value += "{";
                value += "\"Key\":" + tagKey + "," + "\"Value\":" + tagValue.Trim(',');
                value += "},";
                currLine = stringReader.ReadLine();
              }
              value = value.Trim(',');
              value += "],";
            }
            else if (key.EndsWith("configuration_settings\""))
            {
              value += "[";
              currLine = stringReader.ReadLine();
              while (!currLine.StartsWith("}"))
              {
                equalIndex = currLine.IndexOf("=");
                var tagKey = currLine[..equalIndex].Trim();
                if (!tagKey.StartsWith("\""))
                {
                  tagKey = "\"" + tagKey + "\"";
                }
                var tagValue = currLine[(equalIndex + 1)..].Trim();
                value += "{";
                value += "\"Key\":" + tagKey + "," + "\"Value\":" + tagValue.Trim(',');
                value += "},";
                currLine = stringReader.ReadLine();
              }
              value = value.Trim(',');
              value += "],";
            }
            else
            {
              value = currLine[(equalIndex + 1)..].Trim();
              if (!value.EndsWith(",") && !value.EndsWith("{"))
              {
                value += ",";
              }
            }
            if (value != null) jsonString.AppendLine(key + ":" + value);
          }
        }
      }
      return jsonString.ToString();
    }

    public static async Task<AppFile> GetImagesFile(ITableStorageService<AppFile> appFileService)
    {
      string filename = "VM-Images.json";
      string partitionKey = "VM";
      AppFile file = null;
      try
      {
        file = await appFileService.GetByIdAsync(filename, partitionKey);
        if (file == null) throw new KeyNotFoundException();
      }
      catch
      {
        byte[] byteContent = System.IO.File.ReadAllBytes("ParameterDetails/" + filename);

        using MemoryStream memory = new(byteContent);
        file = new AppFile()
        {
          Id = WebUtility.HtmlEncode(filename),
          Content = byteContent,
          UntrustedName = filename,
          Size = memory.Length,
          UploadDT = DateTime.UtcNow
        };
      }
      return file ?? new AppFile();
    }

    public static async Task<ImageDropdown[]> GetOfferedImages(ITableStorageService<AppFile> appFileService)
    {
      try
      {
        AppFile file = await GetImagesFile(appFileService);
        byte[] bytes = file.Content;
        string jsonString = Encoding.UTF8.GetString(bytes);
        ImageDropdown[] images = System.Text.Json.JsonSerializer.Deserialize<ImageDropdown[]>(jsonString);
        return images;
      }
      catch
      {
        return new ImageDropdown[0];
      }
    }

  }
}
