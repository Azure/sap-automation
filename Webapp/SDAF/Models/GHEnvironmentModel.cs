// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Newtonsoft.Json;

namespace SDAFWebApp.Models
{

    public class GHEnvironmentModel
    {
        public long Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string SdafControlPlaneEnvironment { get; set; }
    }

}
