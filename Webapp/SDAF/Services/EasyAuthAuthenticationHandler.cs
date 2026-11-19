// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SDAFWebApp.Models;
using System;
using System.Collections.Generic;
using System.Linq;
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
                Logger.LogInformation(
                    "Easy Auth authentication skipped because ApplicationAuthentication:Enabled is false.");
                return Task.FromResult(AuthenticateResult.NoResult());
            }

            if (!Request.Headers.TryGetValue(ClientPrincipalHeader, out var encodedPrincipal) ||
                string.IsNullOrWhiteSpace(encodedPrincipal))
            {
                Logger.LogInformation(
                    "Easy Auth authentication skipped because the {HeaderName} header is missing or empty.",
                    ClientPrincipalHeader);
                return Task.FromResult(AuthenticateResult.NoResult());
            }

            try
            {
                var payload = Convert.FromBase64String(encodedPrincipal.ToString());
                var principal = JsonSerializer.Deserialize<EasyAuthPrincipal>(payload);
                if (principal?.Claims == null)
                {
                    Logger.LogWarning("Easy Auth authentication failed because the client principal is missing claims.");
                    return Task.FromResult(AuthenticateResult.Fail("The Easy Auth principal is missing claims."));
                }

                var roleClaimType = string.IsNullOrWhiteSpace(principal.RoleClaimType)
                    ? ClaimTypes.Role
                    : principal.RoleClaimType;
                var claims = new List<Claim>(principal.Claims.Count);
                foreach (var claim in principal.Claims)
                {
                    if (!string.IsNullOrWhiteSpace(claim.Type) && claim.Value != null)
                    {
                        claims.Add(new Claim(claim.Type, claim.Value));

                        // Easy Auth can supply either raw Entra roles or mapped .NET role claims.
                        if ((claim.Type == "roles" || claim.Type == ClaimTypes.Role) &&
                            claim.Type != roleClaimType)
                        {
                            claims.Add(new Claim(roleClaimType, claim.Value));
                        }
                    }
                }

                var identity = new ClaimsIdentity(
                    claims,
                    principal.AuthenticationType ?? SchemeName,
                    principal.NameClaimType ?? ClaimTypes.Name,
                    roleClaimType);

                if (Logger.IsEnabled(LogLevel.Information))
                {
                    var roles = identity.FindAll(identity.RoleClaimType)
                        .Select(claim => claim.Value)
                        .Distinct(StringComparer.Ordinal)
                        .ToArray();
                    var userId = identity.FindFirst("http://schemas.microsoft.com/identity/claims/objectidentifier")?.Value
                        ?? identity.FindFirst("oid")?.Value
                        ?? identity.FindFirst(ClaimTypes.NameIdentifier)?.Value
                        ?? "unknown";

                    Logger.LogInformation(
                        "Authenticated user {UserId} has application roles: {Roles} (role claim type: {RoleClaimType}).",
                        userId,
                        roles.Length == 0 ? "(none)" : string.Join(", ", roles),
                        identity.RoleClaimType);
                }

                return Task.FromResult(
                    AuthenticateResult.Success(
                        new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName)));
            }
            catch (Exception exception) when (exception is FormatException or JsonException)
            {
                Logger.LogWarning(
                    "Easy Auth authentication failed because the client-principal header is not valid Base64-encoded JSON.");
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
