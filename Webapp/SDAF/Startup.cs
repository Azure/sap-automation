using AutomationForm.Models;
using AutomationForm.Services;
using Azure.Identity;
using Azure.ResourceManager;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace AutomationForm
{
  public class Startup
  {
    public IConfiguration Configuration { get; }

    public Startup(IConfiguration configuration)
    {
      Configuration = configuration;
    }

    // This method gets called by the runtime. Use this method to add services to the container.
    public void ConfigureServices(IServiceCollection services)
    {
      services.Configure<DatabaseSettings>(
          Configuration.GetSection(nameof(DatabaseSettings)));

      services.AddSingleton<IDatabaseSettings>(sp =>
          sp.GetRequiredService<IOptions<DatabaseSettings>>().Value);

      services.AddSingleton<TableStorageService>();

      services.AddScoped<ITableStorageService<LandscapeEntity>, LandscapeService>();
      services.AddScoped<ITableStorageService<SystemEntity>, SystemService>();
      services.AddScoped<ITableStorageService<AppFile>, AppFileService>();

      services.AddAzureClients(builder =>
      {
        builder.AddClient<ArmClient, ArmClientOptions>((provider, credential, options) =>
          {
            return new ArmClient(new DefaultAzureCredential());
          });
      });

      services.AddControllersWithViews(options =>
      {
        options.Filters.Add<Controllers.ViewBagActionFilter>();
      });
      services.AddRazorPages();
    }

    // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
      if (env.IsDevelopment())
      {
        app.UseDeveloperExceptionPage();
      }
      else
      {
        app.UseExceptionHandler("/Home/Error");
        // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
        app.UseHsts();
      }
      app.UseHttpsRedirection();
      app.UseStaticFiles();

      app.UseRouting();

      app.UseEndpoints(endpoints =>
      {
        endpoints.MapControllerRoute(
                  name: "default",
                  pattern: "{controller=Home}/{action=Index}/{id?}");
        endpoints.MapRazorPages();
      });
    }
  }
}
