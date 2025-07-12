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

To list the availability zone couints for each region, run the following command:

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
1   brazilsouth         3      1 2 3
2   CanadaCentral       3      1 2 3
3   CentralIndia        3      1 2 3
4   centralus           3      1 2 3
5   ChileCentral        3      1 2 3
6   eastasia            3      1 2 3
7   eastus              3      1 2 3
8   eastus2             3      1 2 3
9   EastUS2EUAP         4      1 2 3 4
10  FranceCentral       3      1 2 3
11  GermanyWestCentral  3      1 2 3
12  IndonesiaCentral    3      1 2 3
13  IsraelCentral       3      1 2 3
14  ItalyNorth          3      1 2 3
15  japaneast           3      1 2 3
16  japanwest           3      1 2 3
17  KoreaCentral        3      1 2 3
18  MalaysiaWest        3      1 2 3
19  MexicoCentral       3      1 2 3
20  NewZealandNorth     3      1 2 3
21  northeurope         3      1 2 3
22  NorwayEast          3      1 2 3
23  PolandCentral       3      1 2 3
24  QatarCentral        3      1 2 3
25  SouthAfricaNorth    3      1 2 3
26  southcentralus      3      1 2 3
27  southeastasia       3      1 2 3
28  SpainCentral        3      1 2 3
29  SwedenCentral       3      1 2 3
30  SwitzerlandNorth    3      1 2 3
31  UAENorth            3      1 2 3
32  uksouth             3      1 2 3
33  westeurope          3      1 2 3
34  westus2             3      1 2 3
35  WestUS3             3      1 2 3