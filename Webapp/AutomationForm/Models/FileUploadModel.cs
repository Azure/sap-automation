using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;
using AutomationForm.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Configuration;

namespace AutomationForm.Models
{
    public class FileUploadModel
    {
        [Required]
        [Display(Name = "File")]
        public List<IFormFile> FormFiles { get; set; }
    }
}