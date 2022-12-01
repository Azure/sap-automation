using Newtonsoft.Json;

namespace AutomationForm.Models
{

    public class EnvironmentModel
    {
        public string name { get; set; }
        public string description { get; set; }

        public int id { get; set; }
        public Variables variables { get; set; }
        public VariableGroupProjectReference[] variableGroupProjectReferences { get; set; }
    }

    public class Variables
    {
        public Variable Agent { get; set; }
        public Variable ARM_CLIENT_ID { get; set; }
        public Variable ARM_OBJECT_ID { get; set; }
        public Variable ARM_CLIENT_SECRET { get; set; }
        public Variable ARM_SUBSCRIPTION_ID { get; set; }
        public Variable ARM_TENANT_ID { get; set; }
        public Variable sap_fqdn { get; set; }
        public Variable POOL { get; set; }
    }

    public class Variable
    {
        public string value { get; set; }
        [JsonIgnore]
        public bool? isSecret { get; set; }
        [JsonIgnore]
        public bool? isReadOnly { get; set; }
    }

    public class VariableGroupProjectReference
    {
        public ProjectReference projectReference { get; set; }
        public string name { get; set; }
        public string description { get; set; }
    }

    public class ProjectReference
    {
        public string id { get; set; }
        public string name { get; set; }
    }

}
