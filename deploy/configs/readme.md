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

To list the availability zone counts for each region, run the following command:

```bash
 az vm list-skus --zone --resource-type virtualMachines \
  | jq -r '
  [group_by(.locationInfo[].location | ascii_upcase)[]
  | { Location: .[0].locationInfo[].location,
   Count:[.[] | .locationInfo[].zones] | add | unique | length,
   Zones: [.[] | .locationInfo[].zones] | add | sort | unique | join(" ") }]
  | to_entries | (["#", "Location", "Count", "Zones"]
  | (., map(length*"-"))), (.[] |[.key, .value.Location, .value.Count, .value.Zones])
  | @tsv' \
  | column -ts$'\t'
```

#   Location            Count  Zones
-   --------            -----  -----
0   australiaeast       3      1 2 3
1   austriaeast         3      1 2 3
2   belgiumcentral      3      1 2 3
3   brazilsouth         3      1 2 3
4   canadacentral       3      1 2 3
5   centralindia        3      1 2 3
6   centralus           3      1 2 3
7   chilecentral        3      1 2 3
8   eastasia            3      1 2 3
9   eastus              3      1 2 3
10  eastus2             3      1 2 3
11  eastus2euap         4      1 2 3 4
12  francecentral       3      1 2 3
13  germanywestcentral  3      1 2 3
14  indonesiacentral    3      1 2 3
15  israelcentral       3      1 2 3
16  italynorth          3      1 2 3
17  japaneast           3      1 2 3
18  japanwest           3      1 2 3
19  koreacentral        3      1 2 3
20  malaysiawest        3      1 2 3
21  mexicocentral       3      1 2 3
22  newzealandnorth     3      1 2 3
23  northeurope         3      1 2 3
24  norwayeast          3      1 2 3
25  polandcentral       3      1 2 3
26  qatarcentral        3      1 2 3
27  southafricanorth    3      1 2 3
28  southcentralus      3      1 2 3
29  southeastasia       3      1 2 3
30  spaincentral        3      1 2 3
31  swedencentral       3      1 2 3
32  switzerlandnorth    3      1 2 3
33  uaenorth            3      1 2 3
34  uksouth             3      1 2 3
35  westeurope          3      1 2 3
36  westus2             3      1 2 3
37  westus3             3      1 2 3