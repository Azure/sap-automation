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
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SDAFWebApp.Controllers;
using SDAFWebApp.Models;
using SDAFWebApp.Services;
using System;

namespace SDAFWebApp
{
    public class Startup
    {
        public IConfiguration Configuration { get; }

        public Startup(IConfiguration configuration) => Configuration = configuration;

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.Configure<DatabaseSettings>(
                Configuration.GetSection(nameof(DatabaseSettings)));

            services.Configure<RepositoryPersistenceSettings>(
                Configuration.GetSection(RepositoryPersistenceSettings.SectionName));

            services.AddSingleton<IDatabaseSettings>(sp =>
                sp.GetRequiredService<IOptions<DatabaseSettings>>().Value);

            services.AddSingleton(sp =>
                sp.GetRequiredService<IOptions<RepositoryPersistenceSettings>>().Value);

            services.AddSingleton<IRepositoryPathConvention, RepositoryPathConvention>();

            services.AddSingleton<TableStorageService>();

            // Register RestHelper as singleton (it's stateless and can be reused)
            services.AddSingleton<RestHelper>(provider =>
            {
                string platform = Environment.GetEnvironmentVariable("DEVOPS_PLATFORM")?.ToLower()
                    ?? Configuration["DEVOPS_PLATFORM"]?.ToLower()
                    ?? "ado";
                return new RestHelper(Configuration, platform);
            });

            // Register repository data access provider
            services.AddSingleton<IRepositoryDataAccessProvider, RepositoryDataAccessProvider>();

            // Register storage services (for fallback and legacy support)
            services.AddScoped<LandscapeService>();
            services.AddScoped<SystemService>();
            services.AddScoped<AppFileService>();

            // Register repository implementations
            services.AddScoped<RepositoryLandscapeService>(provider =>
                new RepositoryLandscapeService(
                    provider.GetRequiredService<IRepositoryDataAccessProvider>(),
                    provider.GetRequiredService<IRepositoryPathConvention>(),
                    provider.GetRequiredService<IDatabaseSettings>(),
                    provider.GetRequiredService<LandscapeService>(),
                    provider.GetRequiredService<RestHelper>()));

            services.AddScoped<RepositorySystemService>(provider =>
                new RepositorySystemService(
                    provider.GetRequiredService<IRepositoryDataAccessProvider>(),
                    provider.GetRequiredService<IRepositoryPathConvention>(),
                    provider.GetRequiredService<IDatabaseSettings>(),
                    provider.GetRequiredService<SystemService>(),
                    provider.GetRequiredService<RestHelper>()));

            services.AddScoped<RepositoryAppFileService>(provider =>
                new RepositoryAppFileService(
                    provider.GetRequiredService<IRepositoryDataAccessProvider>(),
                    provider.GetRequiredService<IRepositoryPathConvention>(),
                    provider.GetRequiredService<RestHelper>(),
                    provider.GetRequiredService<IDatabaseSettings>(),
                    provider.GetRequiredService<AppFileService>()));

            // Register selectors that implement repository-first with storage fallback strategy
            services.AddScoped<ITableStorageService<LandscapeEntity>>(provider =>
                new TableStorageServiceSelector<LandscapeEntity>(
                    provider.GetRequiredService<IOptions<RepositoryPersistenceSettings>>(),
                    provider.GetRequiredService<RepositoryLandscapeService>(),
                    provider.GetRequiredService<LandscapeService>(),
                    provider.GetRequiredService<ILogger<TableStorageServiceSelector<LandscapeEntity>>>()));

            services.AddScoped<ITableStorageService<SystemEntity>>(provider =>
                new TableStorageServiceSelector<SystemEntity>(
                    provider.GetRequiredService<IOptions<RepositoryPersistenceSettings>>(),
                    provider.GetRequiredService<RepositorySystemService>(),
                    provider.GetRequiredService<SystemService>(),
                    provider.GetRequiredService<ILogger<TableStorageServiceSelector<SystemEntity>>>()));

            services.AddScoped<ITableStorageService<AppFile>>(provider =>
                new TableStorageServiceSelector<AppFile>(
                    provider.GetRequiredService<IOptions<RepositoryPersistenceSettings>>(),
                    provider.GetRequiredService<RepositoryAppFileService>(),
                    provider.GetRequiredService<AppFileService>(),
                    provider.GetRequiredService<ILogger<TableStorageServiceSelector<AppFile>>>()));

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
