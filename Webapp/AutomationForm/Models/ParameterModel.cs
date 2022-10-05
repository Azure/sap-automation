using Microsoft.AspNetCore.Mvc.Rendering;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class ParameterModel
    {
        public string Name { get; set; }
        public bool Required { get; set; }
        public string Description { get; set; }
        public string Type { get; set; }
        public string Overrules { get; set; }
        public int Display { get; set; }
        public List<SelectListItem> Options { get; set; }
    }
}
