// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

namespace SDAFWebApp.Models
{
    public class FormViewModel<T>
    {
        public Grouping[] ParameterGroupings { get; set; }
        public T SapObject { get; set; }
    }
}
