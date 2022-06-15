using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.Resources.Models;
using System.Diagnostics;
using Microsoft.AspNetCore.Mvc.Rendering;
using Azure.ResourceManager.Network;
using System;

namespace AutomationForm.Controllers
{
    public class ArmclientController : Controller
    {
        private readonly ArmClient _armClient;
        public ArmclientController(ArmClient armClient)
        {
            _armClient = armClient;
        }

        [HttpGet] // #subscription
        public ActionResult GetSubscriptionOptions()
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                SubscriptionContainer subscriptions = _armClient.GetSubscriptions();
                
                foreach (Subscription s in subscriptions.GetAll())
                {
                    options.Add(new SelectListItem
                    {
                        Text = s.Data.SubscriptionGuid,
                        Value = s.Data.Id
                    });
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }

        [HttpGet] // #location
        public ActionResult GetLocationOptions()
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                Subscription subscription = _armClient.DefaultSubscription;
                IEnumerable<Location> locations = subscription.GetLocations();
                
                foreach (Location l in locations)
                {
                    options.Add(new SelectListItem
                    {
                        Text = l.DisplayName,
                        Value = l.Name
                    });
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }

        [HttpGet] // #resourcegroup_arm_id
        public ActionResult GetResourceGroupOptions(string subscriptionId)
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                Subscription subscription = _armClient.GetSubscription(new ResourceIdentifier(subscriptionId));
                ResourceGroupContainer resourceGroups = subscription.GetResourceGroups();
                
                foreach (ResourceGroup r in resourceGroups.GetAll())
                {
                    options.Add(new SelectListItem
                    {
                        Text = r.Data.Name,
                        Value = r.Data.Id
                    });
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }

        [HttpGet] // #network_arm_id
        public ActionResult GetVNetOptions(string subscriptionId)
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                Azure.Pageable<VirtualNetwork> virtualNetworks = _armClient.GetSubscription(new ResourceIdentifier(subscriptionId)).GetVirtualNetworks();
                
                foreach (VirtualNetwork n in virtualNetworks)
                {
                    options.Add(new SelectListItem
                    {
                        Text = n.Data.Name,
                        Value = n.Data.Id
                    });
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }

        [HttpGet] // #[various]_subnet_arm_id
        public ActionResult GetSubnetOptions(string vnetId)
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                ResourceIdentifier id = new ResourceIdentifier(vnetId);
                Subscription subscription = _armClient.GetSubscriptions().Get(id.SubscriptionId);
                ResourceGroup resourceGroup = subscription.GetResourceGroups().Get(id.ResourceGroupName);
                VirtualNetwork virtualNetwork = resourceGroup.GetVirtualNetworks().Get(id.Name);
                SubnetContainer subnets = virtualNetwork.GetSubnets();

                foreach (Subnet s in subnets.GetAll())
                {
                    options.Add(new SelectListItem
                    {
                        Text = s.Data.Name,
                        Value = s.Data.Id
                    });
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }

        [HttpGet] // #[various]_subnet_nsg_arm_id
        public ActionResult GetNsgOptions(string vnetId)
        {
            List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
            try
            {
                ResourceIdentifier id = new ResourceIdentifier(vnetId);
                Subscription subscription = _armClient.GetSubscriptions().Get(id.SubscriptionId);
                ResourceGroup resourceGroup = subscription.GetResourceGroups().Get(id.ResourceGroupName);
                NetworkSecurityGroupContainer nsgs = resourceGroup.GetNetworkSecurityGroups();

                foreach (NetworkSecurityGroup nsg in nsgs.GetAll())
                {
                    options.Add(new SelectListItem
                    {
                        Text = nsg.Data.Name,
                        Value = nsg.Data.Id
                    });
                }
            }
            catch
            {
                return null;
            }
            return Json(options);
        }
    }
}
