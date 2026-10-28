// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    public static class DevOpsHttpClientNames
    {
        public const string AzureDevOps = "AzureDevOps";
        public const string GitHub = "GitHub";
        public const string Unauthenticated = "Unauthenticated";
    }

    public sealed class AzureDevOpsAuthenticationHandler : DelegatingHandler
    {
        private static readonly TokenRequestContext TokenRequestContext =
            new(new[] { "499b84ac-1321-427f-aa17-267ca6975798/.default" });

        private readonly string _authenticationType;
        private readonly string _personalAccessToken;
        private readonly TokenCredential _credential;
        private readonly string _allowedHost;

        public AzureDevOpsAuthenticationHandler(IConfiguration configuration)
        {
            _authenticationType = configuration["AUTHENTICATION_TYPE"];
            _personalAccessToken = configuration["PAT"];
            string collectionUri = configuration["CollectionUri"];

            if (!Uri.TryCreate(collectionUri, UriKind.Absolute, out Uri repositoryUri))
            {
                throw new InvalidOperationException("CollectionUri must be a valid absolute URI.");
            }

            _allowedHost = repositoryUri.Host;

            if (!string.Equals(_authenticationType, "PAT", StringComparison.OrdinalIgnoreCase))
            {
                string tenantId = configuration["AZURE_TENANT_ID"];
                string managedIdentityClientId = configuration["OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"];

                if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(managedIdentityClientId))
                {
                    throw new InvalidOperationException(
                        "AZURE_TENANT_ID and OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID must be configured for managed identity authentication.");
                }

                _credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
                {
                    TenantId = tenantId,
                    ManagedIdentityClientId = managedIdentityClientId
                });
            }
        }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            HttpClientCredentialBoundary.EnsureAllowedHost(request, _allowedHost);

            if (string.Equals(_authenticationType, "PAT", StringComparison.OrdinalIgnoreCase))
            {
                if (string.IsNullOrWhiteSpace(_personalAccessToken))
                {
                    throw new InvalidOperationException("PAT must be configured for PAT authentication.");
                }

                string encodedToken = Convert.ToBase64String(Encoding.ASCII.GetBytes($":{_personalAccessToken}"));
                request.Headers.Authorization = new AuthenticationHeaderValue("Basic", encodedToken);
            }
            else
            {
                AccessToken token = await _credential.GetTokenAsync(TokenRequestContext, cancellationToken);
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);
            }

            return await base.SendAsync(request, cancellationToken);
        }
    }

    public sealed class GitHubAuthenticationHandler : DelegatingHandler
    {
        private readonly IConfiguration _configuration;

        public GitHubAuthenticationHandler(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            HttpClientCredentialBoundary.EnsureAllowedHost(request, "api.github.com");

            string token = _configuration["GITHUB_PAT"];
            if (!string.IsNullOrWhiteSpace(token))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            }

            return base.SendAsync(request, cancellationToken);
        }
    }

    internal static class HttpClientCredentialBoundary
    {
        public static void EnsureAllowedHost(HttpRequestMessage request, string allowedHost)
        {
            if (request.RequestUri is null ||
                !string.Equals(request.RequestUri.Host, allowedHost, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    $"The authenticated HTTP client can only send requests to '{allowedHost}'.");
            }
        }
    }
}
