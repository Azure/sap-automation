# Info

This folder contains the default disk sizing for the different deployment types.

The max_fault_domain_count.json file lists the maximum number of fault domains for each region. The default is 3. It can be created with the following command:

```bash
az vm list-skus --resource-type availabilitySets --query '[?name==`Aligned`].{Location:locationInfo[0].location, MaximumFaultDomainCount:capabilities[0].value}'
```

To list all the Azure regions, run the following command:

```bash

az account list-locations  --query "[?metadata.regionType=='Physical'].name -o Table"

```
