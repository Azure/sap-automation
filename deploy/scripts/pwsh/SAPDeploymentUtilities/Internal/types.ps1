# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Add-Type -TypeDefinition @"
   public enum SAP_Types
   {
      sap_deployer,
      sap_landscape,
      sap_library,
      sap_system
   }
"@