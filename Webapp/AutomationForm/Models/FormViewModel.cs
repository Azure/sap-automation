using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class FormViewModel<T>
    {
        public Grouping[] ParameterGroupings { get; set; }
        public T SapObject { get; set; }
    }
}
