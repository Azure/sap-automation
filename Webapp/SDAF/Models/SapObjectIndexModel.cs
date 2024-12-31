// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System.Collections.Generic;

namespace SDAFWebApp.Models
{
    public class SapObjectIndexModel<T>
    {
        public List<AppFile> AppFiles { get; set; }
        public List<T> SapObjects { get; set; }
        public AppFile ImagesFile { get; set; }

        public SapObjectIndexModel()
        {
            AppFiles = [];
            SapObjects = [];
            ImagesFile = new AppFile();
        }
    }
}
