namespace AutomationForm.Models
{
  public class FormViewModel<T>
  {
    public Grouping[] ParameterGroupings { get; set; }
    public T SapObject { get; set; }
  }
}
