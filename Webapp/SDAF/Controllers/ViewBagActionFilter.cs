// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;
using System;

namespace SDAFWebApp.Controllers
{
    public class ViewBagActionFilter : ActionFilterAttribute
    {
        private readonly IConfiguration _configuration;

        public ViewBagActionFilter(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public override void OnResultExecuting(ResultExecutingContext context)
        {
            if (context.Controller is Controller)
            {
                var controller = context.Controller as Controller;
                controller.ViewBag.IsPipelineDeployment = _configuration["IS_PIPELINE_DEPLOYMENT"];
                controller.ViewBag.adoRepoUrl = String.Format("{0}_git/{1}?path=/WORKSPACES/", _configuration["CollectionUri"], _configuration["ProjectName"]);
                controller.ViewBag.adoPipelineUrl = String.Format("{0}{1}/_build", _configuration["CollectionUri"], _configuration["ProjectName"]);


            }

            base.OnResultExecuting(context);
        }
    }
}
