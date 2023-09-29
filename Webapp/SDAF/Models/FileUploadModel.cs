using Microsoft.AspNetCore.Http;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace AutomationForm.Models
{
  public class FileUploadModel
  {
    [Required]
    [Display(Name = "File")]
    public List<IFormFile> FormFiles { get; set; }
  }
}
