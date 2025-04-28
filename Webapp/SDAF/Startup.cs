// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Azure.Identity;
using Azure.ResourceManager;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using SDAFWebApp.Models;
using SDAFWebApp.Services;
using System;

namespace SDAFWebApp
{
    public class Startup(IConfiguration configuration)
    {
        public IConfiguration Configuration { get; } = configuration;

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
                    return new ArmClient(new DefaultAzureCredential(
                new DefaultAzureCredentialOptions
                    {
                        TenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID"),
                        ManagedIdentityClientId = Environment.GetEnvironmentVariable("OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID")
                    }));
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
