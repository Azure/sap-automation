using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace AutomationForm.Models
{
  public class AppFile
  {
    [DisplayName("File ID")]
    public string Id { get; set; }

    public byte[] Content { get; set; }

    [Display(Name = "File Name")]
    public string UntrustedName { get; set; }

    [Display(Name = "Size (bytes)")]
    [DisplayFormat(DataFormatString = "{0:N0}")]
    public long Size { get; set; }

    [Display(Name = "Uploaded (UTC)")]
    [DisplayFormat(DataFormatString = "{0:G}")]
    public DateTime UploadDT { get; set; }

    public int FileType { get; set; }

  }
}
