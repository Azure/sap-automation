namespace AutomationForm.Models
{
  public class DatabaseSettings : IDatabaseSettings
  {
    public string DatabaseName { get; set; }
    public string LandscapeCollectionName { get; set; }
    public string SystemCollectionName { get; set; }
    public string AppFileCollectionName { get; set; }
    public string AppFileBlobCollectionName { get; set; }
    public string TfVarBlobCollectionName { get; set; }
    public string TemplateCollectionName { get; set; }
    public string ConnectionStringKey { get; set; }
  }

  public interface IDatabaseSettings
  {
    string DatabaseName { get; set; }
    string LandscapeCollectionName { get; set; }
    string SystemCollectionName { get; set; }
    string AppFileCollectionName { get; set; }
    string AppFileBlobCollectionName { get; set; }
    string TfVarBlobCollectionName { get; set; }
    string TemplateCollectionName { get; set; }
    string ConnectionStringKey { get; set; }
  }
}
