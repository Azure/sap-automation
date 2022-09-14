using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

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
        public string workload_environment_parameter { get; set;}
        public string deployer_environment_parameter { get; set; }
        public string deployer_region_parameter { get; set; }
        public string sap_system { get; set; }
        public string environment { get; set; }

    }

}
