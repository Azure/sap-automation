---
name:    'Oracle19_v0001ms'
target:  'Oracle 19'
version: 1

materials:

  media:
    - name:         Oracle Client
      archive:      51054541.zip
      extract:      true
      extractDir:   oraclient
      path:         download_basket
      download:     true
      url:          https://softwaredownloads.sap.com/file/0030000001432222020

    - name:         Oracle Software Server
      archive:      51053828.zip
      extract:      true
      download:     true
      extractDir:   oraserver
      path:         download_basket
      #creates:     SIGNATURE.SMF
      url:          https://softwaredownloads.sap.com/file/0030000002299742019          #Not all S-users have permissions to download the oracle software.


#SBP Patches are downloaded based on SAP Note 2799920 - Patches 19c: Database

    - name:         "Oracle SBP - Bundle patches for 19c: GIRU"
      archive:      GIRU19P_2108-70004508.ZIP
      extract:      false
      download:     true
      extractDir:   SBP/GIRU19P
      path:         SBP
      #creates:     SIGNATURE.SMF
      url:          https://softwaredownloads.sap.com/file/0020000001214732021

    - name:         "Oracle SBP - Bundle patches for 19c: SAP19P"
      archive:      SAP19P_2108-70004508.ZIP
      extract:      true
      download:     true
      extractDir:   SBP/SAPSBP
      path:         SBP
      #creates:     SIGNATURE.SMF
      url:          https://softwaredownloads.sap.com/file/0020000001213832021

    - name:         "Oracle SBP - Bundle patches for 19c: SBPJDK19P"
      archive:      SBPJDK19P_2108-70004508.ZIP
      extract:      false
      download:     true
      extractDir:   SBP/SBPJDK
      path:         SBP
      #creates:     SIGNATURE.SMF
      url:          https://softwaredownloads.sap.com/file/0020000001213892021

    - name:         "Oracle SBP - Bundle patches for 19c: OPatch"
      archive:      OPATCH19P_2105-70004508.ZIP
      extract:      true
      download:     true
      extractDir:   SBP/OPATCH
      path:         SBP
      #creates:     SIGNATURE.SMF
      url:          https://softwaredownloads.sap.com/file/0020000000751692021

#GRID SBP Patching

    - name:         "Oracle SBP - Bundle patches for 19c: GRID Infra"
      archive:      SGR19P_2108-70004550.ZIP
      extract:      true
      download:     true
      extractDir:   SBP/SAPGSBP
      path:         SBP
      url:          https://softwaredownloads.sap.com/file/0020000001217972021

    - name:         "Oracle SBP - Bundle patches for 19c: GRID Infra - GIRU"
      archive:      GIRU19P_2108-70004550.ZIP
      extract:      false
      download:     true
      #extractDir:   SBP
      path:         SBP
      url:          https://softwaredownloads.sap.com/file/0020000001218252021


    
    - name:         "Oracle SBP - Bundle patches for 19c: GRID Infra - SBPJDK"
      archive:      SBPJDK19P_2108-70004550.ZIP
      extract:      false
      download:     true
      #extractDir:   SBP
      path:         SBP
      url:          https://softwaredownloads.sap.com/file/0020000001218012021



    - name:         "Oracle SBP - Bundle patches for 19c: Readme Patch File"
      archive:      README19P_2108-70004508.HTM
      extract:      false
      download:     false
      extractDir:   SBP
      path:         SBP
      #creates:     SIGNATURE.SMF
      url:          https://softwaredownloads.sap.com/file/0020000001213422021

    - name:         "Oracle ASMSUPPORT RPM"
      archive:      oracleasm-support-2.1.12-1.el8.x86_64.rpm
      extract:      false
      download:     true
      url:          https://public-yum.oracle.com/repo/OracleLinux/OL8/addons/x86_64/getPackage/oracleasm-support-2.1.12-1.el8.x86_64.rpm


    - name:         "Oracle ASMLIB RPM"
      archive:      oracleasmlib-2.0.17-1.el8.x86_64.rpm
      extract:      false
      download:     true
      url:          https://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.17-1.el8.x86_64.rpm

    
    - name:         "Oracle compact-lib"
      archive:      compat-libcap1-1.10-7.el7.x86_64.rpm
      extract:      false
      download:     true
      url:          https://public-yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/compat-libcap1-1.10-7.el7.x86_64.rpm


    - name:         "Oracle ASMSUPPORT RPM"
      archive:      oracleasm-support-2.1.12-1.el8.x86_64.rpm
      extract:      false
      download:     true
      url:          https://public-yum.oracle.com/repo/OracleLinux/OL8/addons/x86_64/getPackage/oracleasm-support-2.1.12-1.el8.x86_64.rpm


    - name:         "Oracle ASMLIB RPM"
      archive:      oracleasmlib-2.0.17-1.el8.x86_64.rpm
      extract:      false
      download:     true
      url:          https://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.17-1.el8.x86_64.rpm

    
    - name:         "Oracle compact-lib"
      archive:      compat-libcap1-1.10-7.el7.x86_64.rpm
      extract:      false
      download:     true
      url:          https://public-yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/compat-libcap1-1.10-7.el7.x86_64.rpm

...
