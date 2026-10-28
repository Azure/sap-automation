// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Threading.Tasks;

namespace SDAFWebApp.Services
{
    public class EasyAuthAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        public const string SchemeName = "EasyAuth";
        private const string ClientPrincipalHeader = "X-MS-CLIENT-PRINCIPAL";
        private readonly ApplicationAuthenticationSettings _settings;

        public EasyAuthAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            IOptions<ApplicationAuthenticationSettings> settings)
            : base(options, logger, encoder)
        {
            _settings = settings.Value;
        }

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!_settings.Enabled)
            {
                return Task.FromResult(AuthenticateResult.NoResult());
            }

            if (!Request.Headers.TryGetValue(ClientPrincipalHeader, out var encodedPrincipal) ||
                string.IsNullOrWhiteSpace(encodedPrincipal))
            {
                return Task.FromResult(AuthenticateResult.NoResult());
            }

            try
            {
                var payload = Convert.FromBase64String(encodedPrincipal.ToString());
                var principal = JsonSerializer.Deserialize<EasyAuthPrincipal>(payload);
                if (principal?.Claims == null)
                {
                    return Task.FromResult(AuthenticateResult.Fail("The Easy Auth principal is missing claims."));
                }

                var claims = new List<Claim>(principal.Claims.Count);
                foreach (var claim in principal.Claims)
                {
                    if (!string.IsNullOrWhiteSpace(claim.Type) && claim.Value != null)
                    {
                        claims.Add(new Claim(claim.Type, claim.Value));
                    }
                }

                var identity = new ClaimsIdentity(
                    claims,
                    principal.AuthenticationType ?? SchemeName,
                    principal.NameClaimType ?? ClaimTypes.Name,
                    principal.RoleClaimType ?? ClaimTypes.Role);

                return Task.FromResult(
                    AuthenticateResult.Success(
                        new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName)));
            }
            catch (Exception exception) when (exception is FormatException or JsonException)
            {
                return Task.FromResult(AuthenticateResult.Fail("The Easy Auth principal header is invalid."));
            }
        }

        private sealed class EasyAuthPrincipal
        {
            [System.Text.Json.Serialization.JsonPropertyName("auth_typ")]
            public string AuthenticationType { get; set; }

            [System.Text.Json.Serialization.JsonPropertyName("name_typ")]
            public string NameClaimType { get; set; }

            [System.Text.Json.Serialization.JsonPropertyName("role_typ")]
            public string RoleClaimType { get; set; }

            [System.Text.Json.Serialization.JsonPropertyName("claims")]
            public List<EasyAuthClaim> Claims { get; set; }
        }

        private sealed class EasyAuthClaim
        {
            [System.Text.Json.Serialization.JsonPropertyName("typ")]
            public string Type { get; set; }

            [System.Text.Json.Serialization.JsonPropertyName("val")]
            public string Value { get; set; }
        }
    }
}
