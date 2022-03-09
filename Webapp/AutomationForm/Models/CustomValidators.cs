using AutomationForm.Controllers;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace AutomationForm.Models
{
    public class CustomValidators
    {
        public class LocationValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                if (value != null && Helper.regionMapping.ContainsKey((string)value)) return true;
                else return false;
            }
        }
        private static bool RegexValidation(object value, string pattern)
        {
            if (value == null || Regex.IsMatch((string)value, pattern)) return true;
            else return false;
        }
        public class IpAddressValidator : ValidationAttribute
        {
            public override bool IsValid(object value)
            {
                string pattern = @"^\d+\.\d+\.\d+\.\d+\/\d+$";
                return RegexValidation(value, pattern);
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
                string prefix = (string)value;
                string armId = (string)context.ObjectInstance.GetType().GetProperty("network_address_arm_id").GetValue(context.ObjectInstance);

                if (prefix == null && armId == null)
                {
                    return new ValidationResult($"At least one of network_address_space or network_address_arm_id must be present.");
                }
                else
                {
                    return ValidationResult.Success;
                }
            }
        }

    }
}
