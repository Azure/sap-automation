using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class RefModel
    {
        public Value[] value { get; set; }
        public int count { get; set; }
    }

    public class Value
    {
        public string name { get; set; }
        public string objectId { get; set; }
        public Creator creator { get; set; }
        public string url { get; set; }
    }

    public class Creator
    {
        public string displayName { get; set; }
        public string url { get; set; }
        public Links _links { get; set; }
        public string id { get; set; }
        public string uniqueName { get; set; }
        public string imageUrl { get; set; }
        public string descriptor { get; set; }
    }

    public class Links
    {
        public Avatar avatar { get; set; }
    }

    public class Avatar
    {
        public string href { get; set; }
    }

}
