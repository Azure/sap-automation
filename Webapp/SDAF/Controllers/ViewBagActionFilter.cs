// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;

namespace SDAFWebApp.Controllers
{
    public class ViewBagActionFilter(IConfiguration configuration) : ActionFilterAttribute
    {
        private readonly IConfiguration _configuration = configuration;

        public override void OnResultExecuting(ResultExecutingContext context)
        {
            if (context.Controller is Controller)
            {
                var controller = context.Controller as Controller;
                controller.ViewBag.IsPipelineDeployment = _configuration["IS_PIPELINE_DEPLOYMENT"];
            }

            base.OnResultExecuting(context);
        }
    }
}
