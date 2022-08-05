using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class LandscapeIndexModel
    {
        public List<AppFile> AppFiles { get; set; }
        public List<LandscapeModel> Landscapes { get; set; }

        public LandscapeIndexModel()
        {
            AppFiles = new List<AppFile>();
            Landscapes = new List<LandscapeModel>();
        }
    }
}
