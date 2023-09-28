using System.Collections.Generic;

namespace AutomationForm.Models
{
  public class SapObjectIndexModel<T>
  {
    public List<AppFile> AppFiles { get; set; }
    public List<T> SapObjects { get; set; }
    public AppFile ImagesFile { get; set; }

    public SapObjectIndexModel()
    {
      AppFiles = new List<AppFile>();
      SapObjects = new List<T>();
      ImagesFile = new AppFile();
    }
  }
}
