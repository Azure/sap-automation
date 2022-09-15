using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class Grouping
    {
        public string Section { get; set; }
        public string Link { get; set; }
        public ParameterModel[] Parameters { get; set; }
    }
}