// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System;
using System.IO;
using System.Text.RegularExpressions;

namespace SDAFWebApp.Services
{
    public readonly record struct WorkloadZoneIdentifier(string Environment, string LocationCode, string NetworkLogicalName)
    {
        public string Value => $"{Environment}-{LocationCode}-{NetworkLogicalName}";
    }

    public readonly record struct SystemIdentifier(
        string Environment,
        string LocationCode,
        string NetworkLogicalName,
        string Sid)
    {
        public string Value => $"{Environment}-{LocationCode}-{NetworkLogicalName}-{Sid}";
        public string PartitionKey => Environment;
    }

    public enum AppFileKind
    {
        TerraformVariables,
        CustomNaming,
        CustomSizes,
        VmImages
    }

    public readonly record struct AppFileIdentifier(
        string FileName,
        string PartitionKey,
        string ObjectId,
        AppFileKind Kind);

    /// <summary>
    /// Parses persistence identifiers. These methods deliberately reject paths:
    /// callers must pass a single identifier or file name, never a repository path.
    /// </summary>
    public static class IdentifierParser
    {
        private static readonly Regex SegmentPattern = new(
            "^[A-Za-z0-9_]+$",
            RegexOptions.CultureInvariant | RegexOptions.Compiled,
            TimeSpan.FromMilliseconds(100));

        public static bool TryParseWorkloadZone(
            string value,
            out WorkloadZoneIdentifier identifier,
            out string error)
        {
            identifier = default;
            if (!TryValidateIdentifier(value, "Workload-zone ID", out error))
            {
                return false;
            }

            string[] parts = value.Split('-', StringSplitOptions.None);
            if (parts.Length != 3 || !AllSegmentsValid(parts))
            {
                error = "Workload-zone ID must contain environment, location code, and network name separated by hyphens.";
                return false;
            }

            identifier = new WorkloadZoneIdentifier(parts[0], parts[1], parts[2]);
            return true;
        }

        public static bool TryParseSystem(
            string value,
            out SystemIdentifier identifier,
            out string error)
        {
            identifier = default;
            if (!TryValidateIdentifier(value, "System ID", out error))
            {
                return false;
            }

            string[] parts = value.Split('-', StringSplitOptions.None);
            if (parts.Length != 4 || !AllSegmentsValid(parts))
            {
                error = "System ID must contain environment, location code, network name, and SID separated by hyphens.";
                return false;
            }

            identifier = new SystemIdentifier(parts[0], parts[1], parts[2], parts[3]);
            return true;
        }

        public static bool TryParseAppFile(
            string value,
            out AppFileIdentifier identifier,
            out string error)
        {
            identifier = default;
            if (!TryValidateFileName(value, out error))
            {
                return false;
            }

            if (value.Equals("VM-Images.json", StringComparison.OrdinalIgnoreCase))
            {
                identifier = new AppFileIdentifier(value, "VM", "VM", AppFileKind.VmImages);
                return true;
            }

            const string namingSuffix = "_custom_naming.json";
            const string sizesSuffix = "_custom_sizes.json";
            if (value.EndsWith(namingSuffix, StringComparison.OrdinalIgnoreCase) ||
                value.EndsWith(sizesSuffix, StringComparison.OrdinalIgnoreCase))
            {
                string suffix = value.EndsWith(namingSuffix, StringComparison.OrdinalIgnoreCase)
                    ? namingSuffix
                    : sizesSuffix;
                string systemValue = value[..^suffix.Length];
                if (!TryParseSystem(systemValue, out SystemIdentifier system, out error))
                {
                    error = $"Custom file name contains an invalid system ID. {error}";
                    return false;
                }

                AppFileKind kind = suffix == namingSuffix
                    ? AppFileKind.CustomNaming
                    : AppFileKind.CustomSizes;
                identifier = new AppFileIdentifier(value, system.PartitionKey, system.Value, kind);
                return true;
            }

            if (!value.EndsWith(".tfvars", StringComparison.OrdinalIgnoreCase))
            {
                error = "App file must be a .tfvars file, a supported custom JSON file, or VM-Images.json.";
                return false;
            }

            string objectValue = value[..^".tfvars".Length];
            if (objectValue.EndsWith("-INFRASTRUCTURE", StringComparison.OrdinalIgnoreCase))
            {
                string zoneValue = objectValue[..^"-INFRASTRUCTURE".Length];
                if (!TryParseWorkloadZone(zoneValue, out WorkloadZoneIdentifier zone, out error))
                {
                    error = $"Infrastructure file name contains an invalid workload-zone ID. {error}";
                    return false;
                }

                identifier = new AppFileIdentifier(value, zone.Environment, zone.Value, AppFileKind.TerraformVariables);
                return true;
            }

            if (!TryParseSystem(objectValue, out SystemIdentifier systemIdentifier, out error))
            {
                error = $"TFVars file name contains an invalid system ID. {error}";
                return false;
            }

            identifier = new AppFileIdentifier(
                value,
                systemIdentifier.PartitionKey,
                systemIdentifier.Value,
                AppFileKind.TerraformVariables);
            return true;
        }

        public static AppFileIdentifier ParseAppFile(string value)
        {
            if (!TryParseAppFile(value, out AppFileIdentifier identifier, out string error))
            {
                throw new ArgumentException(error, nameof(value));
            }

            return identifier;
        }

        public static SystemIdentifier ParseSystem(string value)
        {
            if (!TryParseSystem(value, out SystemIdentifier identifier, out string error))
            {
                throw new ArgumentException(error, nameof(value));
            }

            return identifier;
        }

        public static WorkloadZoneIdentifier ParseWorkloadZone(string value)
        {
            if (!TryParseWorkloadZone(value, out WorkloadZoneIdentifier identifier, out string error))
            {
                throw new ArgumentException(error, nameof(value));
            }

            return identifier;
        }

        private static bool TryValidateIdentifier(string value, string displayName, out string error)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                error = $"{displayName} is required.";
                return false;
            }

            if (value.Contains("..", StringComparison.Ordinal) ||
                value.Contains('/') ||
                value.Contains('\\') ||
                Path.IsPathRooted(value))
            {
                error = $"{displayName} cannot contain a path or traversal sequence.";
                return false;
            }

            error = null;
            return true;
        }

        private static bool TryValidateFileName(string value, out string error)
        {
            if (!TryValidateIdentifier(value, "File name", out error))
            {
                return false;
            }

            if (!string.Equals(Path.GetFileName(value), value, StringComparison.Ordinal))
            {
                error = "File name must not contain a directory.";
                return false;
            }

            if (value.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
            {
                error = "File name contains an invalid character.";
                return false;
            }

            return true;
        }

        private static bool AllSegmentsValid(string[] parts)
        {
            foreach (string part in parts)
            {
                if (!SegmentPattern.IsMatch(part))
                {
                    return false;
                }
            }

            return true;
        }
    }
}
