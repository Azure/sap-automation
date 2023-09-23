using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;

namespace AutomationForm.Controllers
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
      }

      base.OnResultExecuting(context);
    }
  }
}
