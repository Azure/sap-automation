using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class SystemIndexModel
    {
        public List<AppFile> AppFiles { get; set; }
        public List<SystemModel> Systems { get; set; }
        public AppFile ImagesFile { get; set; }

        public SystemIndexModel()
        {
            AppFiles = new List<AppFile>();
            Systems = new List<SystemModel>();
            ImagesFile = new AppFile();
        }
    }
}
