namespace AutomationForm.Models
{

  public class GitRequestBody
  {
    public Refupdate[] refUpdates { get; set; }
    public Commit[] commits { get; set; }
  }

  public class Refupdate
  {
    public string name { get; set; }
    public string oldObjectId { get; set; }
  }

  public class Commit
  {
    public string comment { get; set; }
    public Change[] changes { get; set; }
  }

  public class Change
  {
    public string changeType { get; set; }
    public Item item { get; set; }
    public Newcontent newContent { get; set; }
  }

  public class Item
  {
    public string path { get; set; }
  }

  public class Newcontent
  {
    public string content { get; set; }
    public string contentType { get; set; }
  }

}
