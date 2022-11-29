using AutomationForm.Controllers;
using System;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.RegularExpressions;

namespace AutomationForm.Models
{
    public class CustomValidators
    {
        public class RequiredIfNotDefault : RequiredAttribute
        {
            protected override ValidationResult IsValid(object value, ValidationContext context)
            {
                bool isDefault = (bool)context.ObjectInstance.GetType().GetProperty("IsDefault").GetValue(context.ObjectInstance);
                if (isDefault) return ValidationResult.Success;
                else
                {
                    if (base.IsValid(value))
                    {
                        return ValidationResult.Success;
                    }
                    else return new ValidationResult(ErrorMessage);
                }
            }
        }
        public class LocationValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                if (value == null) return true;
                if (value != null && Helper.regionMapping.ContainsKey((string)value)) return true;
                else return false;
            }
        }
        private static bool RegexValidation(object value, string pattern)
        {
            if (value == null || Regex.IsMatch((string)value, pattern)) return true;
            else return false;
        }
        public class AddressPrefixValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\d+\.\d+\.\d+\.\d+\/\d+$";
                return RegexValidation(value, pattern);
            }
        }
        public class IpAddressValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                if (value == null) return true;
                string pattern = @"^\d+\.\d+\.\d+\.\d+$";
                if (!value.GetType().IsArray) return false;
                string[] values = (string[])value;
                foreach (string v in values)
                {
                    if (!RegexValidation(v, pattern)) return false;
                }
                return true;

            }
        }
        public class SubnetArmIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class NsgArmIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class NetworkAddressValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class RgArmIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class SubscriptionIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$";
                return RegexValidation(value, pattern);
            }
        }
        public class KeyvaultIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.KeyVault\/vaults\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class PrivateEndpointIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/privateEndpoints\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class StorageAccountIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Storage\/storageAccounts\/[a-zA-Z0-9-_]+$";
                return RegexValidation(value, pattern);
            }
        }
        public class GuidValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                if (value == null) return true;
                string pattern = @"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}";
                if (value.GetType().IsArray)
                {
                    string[] values = (string[])value;
                    foreach (string v in values)
                    {
                        if (!RegexValidation(v, pattern)) return false;
                    }
                    return true;
                }
                else if (value.GetType() == typeof(string))
                {
                    return RegexValidation(value, pattern);
                }
                else
                {
                    return false;
                }
            }
        }
        public class AvSetIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                if (value == null) return true;
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Compute\/availabilitySets\/[a-zA-Z0-9-_]+$";
                if (value.GetType().IsArray)
                {
                    string[] values = (string[])value;
                    foreach (string v in values)
                    {
                        if (!RegexValidation(v, pattern)) return false;
                    }
                    return true;
                }
                else if (value.GetType() == typeof(string))
                {
                    return RegexValidation(value, pattern);
                }
                else
                {
                    return false;
                }
            }
        }
        public class PpgIdValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                if (value == null) return true;
                string pattern = @"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Compute\/proximityPlacementGroups\/[a-zA-Z0-9-_]+$";
                if (value.GetType().IsArray)
                {
                    string[] values = (string[])value;
                    foreach (string v in values)
                    {
                        if (!RegexValidation(v, pattern)) return false;
                    }
                    return true;
                }
                else if (value.GetType() == typeof(string))
                {
                    return RegexValidation(value, pattern);
                }
                else
                {
                    return false;
                }
            }
        }
        public class SubnetRequired : ValidationAttribute
        {
            private readonly string thisProperty;
            private readonly string targetProperty;
            public SubnetRequired(string subnetType)
            {
                thisProperty = subnetType + "_subnet_address_prefix";
                targetProperty = subnetType + "_subnet_arm_id";
            }
            protected override ValidationResult IsValid(object value, ValidationContext context)
            {
                bool isDefault = (bool)context.ObjectInstance.GetType().GetProperty("IsDefault").GetValue(context.ObjectInstance);
                if (isDefault) return ValidationResult.Success;

                string prefix = (string)value;
                string armId = (string)context.ObjectInstance.GetType().GetProperty(targetProperty).GetValue(context.ObjectInstance);

                if (prefix == null && armId == null)
                {
                    return new ValidationResult($"At least one of {thisProperty} or {targetProperty} must be present.");
                }
                else
                {
                    return ValidationResult.Success;
                }
            }
        }

        public class VnetRequired : ValidationAttribute
        {
            protected override ValidationResult IsValid(object value, ValidationContext context)
            {
                bool isDefault = (bool)context.ObjectInstance.GetType().GetProperty("IsDefault").GetValue(context.ObjectInstance);
                if (isDefault) return ValidationResult.Success;

                string prefix = (string)value;
                string armId = (string)context.ObjectInstance.GetType().GetProperty("network_arm_id").GetValue(context.ObjectInstance);

                if (prefix == null && armId == null)
                {
                    return new ValidationResult($"At least one of network_address_space or network_arm_id must be present.");
                }
                else
                {
                    return ValidationResult.Success;
                }
            }
        }

        public class DatabasePlatformValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string[] acceptedPlatforms = new string[] {
                    "HANA",
                    "DB2",
                    "ORACLE",
                    "ASE",
                    "SQLSERVER",
                    "NONE"
                };
                return (value == null) || acceptedPlatforms.Contains(value);
            }
        }
        public class DatabaseSizeValidator : ValidationAttribute
        {
            protected override ValidationResult IsValid(object value, ValidationContext context)
            {
                string[] hanadb_sizes = new string[] {
                    "Default",
                    "S4Demo",
                    "E20ds_v4",
                    "E20ds_v5",
                    "E32ds_v4",
                    "E32ds_v5",
                    "E48ds_v4",
                    "E48ds_v5",
                    "E64s_v3",
                    "E64ds_v4",
                    "E64ds_v5",
                    "E96ds_v5",
                    "M32ts",
                    "M32ls",
                    "M64ls",
                    "M64s",
                    "M64ms",
                    "M128s",
                    "M128ms",
                    "M208s_v2",
                    "M208ms_v2",
                    "M416s_v2",
                    "M416ms_v2"
                };
                string[] anydb_sizes = new string[] {
                    "Default",
                    "256",
                    "512",
                    "1024",
                    "2048",
                    "5120",
                    "10240",
                    "15360",
                    "20480",
                    "30720",
                    "40960",
                    "51200"
                };
                string size = (string)value;
                string platform = (string)context.ObjectInstance.GetType().GetProperty("database_platform").GetValue(context.ObjectInstance);
                if (platform == null)
                {
                    if (size == null || hanadb_sizes.Contains(size) || anydb_sizes.Contains(size))
                    {
                        return ValidationResult.Success;
                    }
                    else
                    {
                        return new ValidationResult("The field database_size is invalid.");
                    }
                }
                else if (platform == "HANA")
                {
                    if (hanadb_sizes.Contains(size))
                    {
                        return ValidationResult.Success;
                    }
                    else
                    {
                        return new ValidationResult("Invalid size for HANA database platform");
                    }
                }
                else
                {
                    if (anydb_sizes.Contains(size))
                    {
                        return ValidationResult.Success;
                    }
                    else
                    {
                        return new ValidationResult($"Invalid size for {platform} database platform");
                    }
                }
            }
        }
    }
}
