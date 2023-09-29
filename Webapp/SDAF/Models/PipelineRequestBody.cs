namespace AutomationForm.Models
{

  public class PipelineRequestBody
  {
    public Resources resources { get; set; }
    public Templateparameters templateParameters { get; set; }
  }

  public class Resources
  {
    public Repositories repositories { get; set; }
  }

  public class Repositories
  {
    public Self self { get; set; }
  }

  public class Self
  {
    public string refName { get; set; }
  }

  public class Templateparameters
  {
    public string workload_zone { get; set; }
    public string workload_environment_parameter { get; set; }
    public string deployer_environment_parameter { get; set; }
    public string deployer_region_parameter { get; set; }
    public string sap_system { get; set; }
    public string environment { get; set; }
    public string sap_system_configuration_name { get; set; }
    public string bom_base_name { get; set; }
    public string extra_params { get; set; }
    public bool? base_os_configuration { get; set; }
    public bool? sap_os_configuration { get; set; }
    public bool? bom_processing { get; set; }
    public bool? database_install { get; set; }
    public bool? scs_installation { get; set; }
    public bool? db_load { get; set; }
    public bool? high_availability_configuration { get; set; }
    public bool? pas_installation { get; set; }
    public bool? application_server_installation { get; set; }
    public bool? webdispatcher_installation { get; set; }
    public bool? acss_registration { get; set; }
    public string acss_environment { get; set; }
    public string acss_sap_product { get; set; }

  }

}
