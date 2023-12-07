using Azure;
using Azure.Core;
using Azure.ResourceManager;
using Azure.ResourceManager.Compute;
using Azure.ResourceManager.KeyVault;
using Azure.ResourceManager.Network;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.Storage;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Collections.Generic;

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
      List<SelectListItem> options = new()
      {
          new SelectListItem { Text = "", Value = "" }
      };
      try
      {
        SubscriptionCollection subscriptions = _armClient.GetSubscriptions();

        foreach (SubscriptionResource s in subscriptions.GetAll())
        {
          options.Add(new SelectListItem
          {
            Text = s.Data.DisplayName,
            Value = s.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // # populate subscription from existing resource arm id (for edit view)
    public ActionResult GetSubscriptionFromResource(string resourceId)
    {
      try
      {
        ResourceIdentifier rsc = new(resourceId);
        if (rsc.SubscriptionId == null) return null;
        string subscriptionId = "/subscriptions/" + rsc.SubscriptionId;
        return Json(subscriptionId);
      }
      catch
      {
        return null;
      }
    }

    [HttpGet] // # populate network_arm_id from existing resource arm id (for edit view)
    public ActionResult GetVnetFromResource(string resourceId)
    {
      try
      {
        ResourceIdentifier rsc = new(resourceId);
        if (rsc.SubscriptionId == null) return null;
        int subnetsIndex = resourceId.IndexOf("/subnets");
        if (subnetsIndex <= 0) return null;
        string vnetId = resourceId.Substring(0, resourceId.IndexOf("/subnets"));
        return Json(vnetId);
      }
      catch
      {
        return null;
      }
    }

    [HttpGet] // #location
    public ActionResult GetLocationOptions(bool useRegionMapping = false)
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        Dictionary<string, string> regionMapping = Helper.regionMapping;
        foreach (string region in regionMapping.Keys)
        {
          options.Add(new SelectListItem
          {
            Text = region,
            Value = useRegionMapping ? Helper.MapRegion(region).ToUpper() : region
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
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        ResourceGroupCollection resourceGroups = subscription.GetResourceGroups();

        foreach (ResourceGroupResource r in resourceGroups.GetAll())
        {
          options.Add(new SelectListItem
          {
            Text = r.Data.Name,
            Value = r.Id
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
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<VirtualNetworkResource> virtualNetworks = subscription.GetVirtualNetworks();

        foreach (VirtualNetworkResource n in virtualNetworks)
        {
          options.Add(new SelectListItem
          {
            Text = n.Data.Name,
            Value = n.Id
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
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        ResourceIdentifier id = new(vnetId);
        SubscriptionResource subscription = _armClient.GetSubscriptions().Get(id.SubscriptionId);
        ResourceGroupResource resourceGroup = subscription.GetResourceGroups().Get(id.ResourceGroupName);
        VirtualNetworkResource virtualNetwork = resourceGroup.GetVirtualNetworks().Get(id.Name);
        SubnetCollection subnets = virtualNetwork.GetSubnets();

        foreach (SubnetResource s in subnets.GetAll())
        {
          options.Add(new SelectListItem
          {
            Text = s.Data.Name,
            Value = s.Id
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
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        ResourceIdentifier id = new(vnetId);
        SubscriptionResource subscription = _armClient.GetSubscriptions().Get(id.SubscriptionId);
        ResourceGroupResource resourceGroup = subscription.GetResourceGroups().Get(id.ResourceGroupName);
        NetworkSecurityGroupCollection nsgs = resourceGroup.GetNetworkSecurityGroups();

        foreach (NetworkSecurityGroupResource nsg in nsgs.GetAll())
        {
          options.Add(new SelectListItem
          {
            Text = nsg.Data.Name,
            Value = nsg.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // #[various]_storage_account_arm_id
    public ActionResult GetStorageAccountOptions(string subscriptionId)
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<StorageAccountResource> storageAccounts = subscription.GetStorageAccounts();

        foreach (StorageAccountResource sa in storageAccounts)
        {
          try
          {
            SelectListItem li = new SelectListItem
            {
              Text = sa.Data.Name,
              Value = sa.Id
            };
            options.Add(li);
          }
          catch (System.Exception Ex)
          {
            string errorMessage = Ex.Message;
          }

        }
      }
      catch(System.Exception Ex)
      {
        string errorMessage= Ex.Message;
      }
      return Json(options);
    }

    [HttpGet] // #[various]_private_endpoint_id
    public ActionResult GetPrivateEndpointOptions(string subscriptionId)
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<PrivateEndpointResource> privateEndpoints = subscription.GetPrivateEndpoints();

        foreach (PrivateEndpointResource pe in privateEndpoints)
        {
          options.Add(new SelectListItem
          {
            Text = pe.Data.Name,
            Value = pe.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // #[various]_keyvault_id
    public ActionResult GetKeyvaultOptions(string subscriptionId)
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<KeyVaultResource> keyVaults = subscription.GetKeyVaults();

        foreach (KeyVaultResource kv in keyVaults)
        {
          options.Add(new SelectListItem
          {
            Text = kv.Data.Name,
            Value = kv.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // #proximityplacementgroup_arm_ids
    public ActionResult GetPPGroupOptions(string subscriptionId)
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<ProximityPlacementGroupResource> ppgs = subscription.GetProximityPlacementGroups();

        foreach (ProximityPlacementGroupResource ppg in ppgs)
        {
          options.Add(new SelectListItem
          {
            Text = ppg.Data.Name,
            Value = ppg.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // #[various]_avset_arm_id
    public ActionResult GetAvSetOptions(string subscriptionId)
    {
      List<SelectListItem> options = new()
      {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<AvailabilitySetResource> avs = subscription.GetAvailabilitySets();

        foreach (AvailabilitySetResource av in avs)
        {
          options.Add(new SelectListItem
          {
            Text = av.Data.Name,
            Value = av.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // #[various]_user_assigned_identity_id
    public ActionResult GetUserAssignedIdentityOptions(string subscriptionId)
    {
      List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<GenericResource> userIDs = subscription.GetGenericResources("resourceType eq 'Microsoft.ManagedIdentity/userAssignedIdentities'");

        foreach (GenericResource userId in userIDs)
        {
          options.Add(new SelectListItem
          {
            Text = userId.Data.Name,
            Value = userId.Id
          });
        }
      }
      catch
      {
        return null;
      }
      return Json(options);
    }

    [HttpGet] // #[various]_user_assigned_identity_id
    public ActionResult GetVMSSOptions(string subscriptionId)
    {
      List<SelectListItem> options = new List<SelectListItem>
            {
                new SelectListItem { Text = "", Value = "" }
            };
      try
      {
        SubscriptionResource subscription = _armClient.GetSubscriptionResource(new ResourceIdentifier(subscriptionId));
        Pageable<GenericResource> userIDs = subscription.GetGenericResources("resourceType eq 'Microsoft.Compute/virtualMachineScaleSets'");

        foreach (GenericResource userId in userIDs)
        {
          options.Add(new SelectListItem
          {
            Text = userId.Data.Name,
            Value = userId.Id
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
