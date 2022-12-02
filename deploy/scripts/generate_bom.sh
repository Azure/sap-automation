#!/bin/bash

# Requires:
# - a stack XML file (*.xml)
# - a stack Excel file (*.xls)
# - a download basket manifest (*.json)
# The script discovers the filenames based on the file extension.
# NOTE: Exactly one of each file is allowed!
# Limitations of generated BoM:
# - Hard-coded HANA2 dependency which will need editing
#
# Instructions
# - Run this script from the stackfiles folder on your workstation
#   /path/to/generate_fullbom.sh [product] >path/to/bom.yml
#   where:
#   - `product` is the documented root BoM name, e.g. "SAP_S4HANA_1809_SP5_v001"
#     If not supplied or blank, it will attempt to determine the name from the stack XML file.
#   For example:
#   cd stackfiles
#   /path/to/util/generate_fullbom.sh "SAP_S4HANA_1809_SP5_v001" >../bom.yml

declare PRODUCT=${1}

declare ERR=0

declare -a XML_FILE=($(ls *.xml 2>/dev/null))
if [[ ${#XML_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .xml file is required. I have found ${XML_FILE[*]:-none}"
  ERR=1
fi

declare -a XLS_FILE=($(ls *.xls 2>/dev/null))
if [[ ${#XLS_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .xls file is required. I have found ${XLS_FILE[*]:-none}"
  ERR=1
fi

declare -a JSON_FILE=($(ls *.json 2>/dev/null))
if [[ ${#JSON_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .json file is required. I have found ${JSON_FILE[*]:-none}"
  ERR=1
fi

jq '.d.results[].Value' ${JSON_FILE[0]}  > values.params

declare -a PARAMS_FILE=($(ls *.params 2>/dev/null))
if [[ ${#PARAMS_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .params file is required. I have found ${PARAMS_FILE[*]:-none}"
  ERR=1
fi

if [[ ${ERR} -eq 1 ]]; then
  exit 1
fi



awk -v excelfile="${XLS_FILE[0]}" -v downloadmanifestfile="${JSON_FILE[0]}"  -v valuesfile="${PARAMS_FILE[0]}" '
BEGIN {
  sequence["SP_B"] = "AA";  # download_basket
  sequence["CD"] = "BB";    # DVD exports
  sequence["SPAT"] = "CC";  # others
  RScopy = RS;
  RS = "\n";
    
  count = 0;
  #printf("\n%s\n", downloadmanifestfile);

  while ( getline line < valuesfile ) {
   
    if ( match($0, /"Value":/ ) == 0) {
      split(line, value_split, /"/);
      #printf("\n%s", "value split:" value_split[2]);
      id = gensub(/^(.+)\|(.+)$/, "\\1 \\2 \\3", "g", value_split[2]);
      #printf("\n%s", "value of id:" id);
      split(id, result, "|");
      #printf("\n%s", "value of result[1]" result[1]);
      #printf("\n%s", "value of result[2]" result[2]);
      #printf("\n%s", "value of result[3]" result[3]);
      if ( sequence[result[2]] != "" ) {
        seq = sequence[result[2]];
      } else {
        seq = ("ZZ" result[2]);  # Unknown flag
      }
      references[result[3]] = sprintf("%-6s,%s", seq, result[1]);
      
    }
    
  }
  close(downloadmanifestfile);
  RS = RScopy;
}

END {
  RS = "</Row>";
  count = 0;
  while ( getline line < excelfile ) {
    if ( match(line, /ss:StyleID=.s20./) != 0 ) {
      count++;
      # <Data ss:Type="String">K-80401INISPSCA.SAR</Data> ... <Data ss:Type="String">IS-PS-CA 804: SP 0001</Data>
      id = gensub(/.*<Data ss:Type=.String.>([^<]+).*<Data ss:Type=.String.>([^<;]+).*"Number">([^<]+).*$/, "\\1,\\2,\\3", "1", line);
      split(id, basketresults, ",");
      sub(/ +$/, "", basketresults[2]);  # trim line end
      filename = basketresults[1];
      component = basketresults[2];
      componentref = basketresults[3];
      #printf("\n%s", "value of basketresults[1]" basketresults[1]);
      #printf("\n%s", "value of basketresults[2]" basketresults[2]);
      #printf("\n%s", "value of basketresults[3]" basketresults[3]);
      
      if ( references[componentref] != "" ) {
        split(references[componentref], referenceresults, ",");
      } else if ( references[component] != "" ) {
         split(references[component], referenceresults, ",");
      } else {
        split(references[filename], referenceresults, ",");
      }
      
      sapurl = referenceresults[2];
      seq = referenceresults[1];
      if ( sapurl == "" ) seq = "CC";
      printf("%-6s%04d,%s,%s,%s\n", seq, count, sapurl, filename, component) | "sort >tempworkfile1";

      if ( component == "File on DVD" ) seq = "BB";
      printf("%-6s%04d,%s,%s,%s\n", seq, count, sapurl, filename, component) | "sort >tempworkfile";
      printf("%s\n", references[0]) | "sort >tempworkfile1";
    }
  }
  close (excelfile);
  RS = RScopy;
}
' /dev/null

sed -e 's@\(</[^>][^>]*>\)@\1\n@g' ${XML_FILE[0]} | \
awk -v "product=${PRODUCT}" -v "jsonfile=${JSON_FILE}" -v "xlsfile=${XLS_FILE}" -v "xmlfile=${XML_FILE}" '
BEGIN {
  phase = "";
  FS = ",";
}

/<\/constraints>/ {
  systemname = gensub(/^.*<constraint name="ppms-main-app-id"[^>]*description="([^"]+).*$/, "\\1", "1", $0);
  systemname = gensub(/\//, "", "1", systemname);
  systemname = gensub(/[^A-Za-z0-9]+/, "_", "g", systemname);
  if (product == "") product = systemname;
  targetname = gensub(/^.*<constraint name="ppms-nw-id"[^>]*description="([^"]+).*$/, "\\1", "1", $0);
}

END {

  printf("---\n\nname: \"%s\"\ntarget: \"%s\"\n", product, targetname);
  printf("\ndefaults:\n  target_location: \"{{ target_media_location }}/download_basket\"\n");
  printf("\nproduct_ids:\n  scs:\n  scs_ha:\n  dbl:\n  pas:\n  pas_ha:\n  app:\n  app_ha:\n  web:\n  ers:\n  ers_ha:\n");
  printf("\nmaterials:\n  dependencies:\n    - name: \"HANA2\"  # <- edit as needed\n\n  media:\n");

  while ( getline < "tempworkfile" ) {
    seq = $1;
    sapurl = $2;
    filename = $3;
    component = $4;
    if ( component == "File on DVD" ) component = (component " - " $3)

    dir = "";
    current = substr(seq,1,2);
    if (current != phase ) {
      phase = current;
      if ( phase == "AA" ) {
        printf("\n    # kernel components\n");
        # overridedir = "{{ target_media_location }}/download_basket";
      } else if ( phase == "BB" ) {
        printf("\n    # db export components\n");
        # overridedir = "{{ target_media_location }}/cd_exports";
      } else {
        printf("\n    # other components\n");
        # overridedir = "";
      }
    }

    printf("\n    - name: \"%s\"\n", component);
    printf("      archive: %s\n", filename);
    if ( overridedir != "") printf("      override_target_location: \"%s\"\n", overridedir);
    if (match(filename, /SAPCAR_.*\.EXE/ ) != 0) printf("      override_target_filename: \"SAPCAR.EXE\"\n");
    if (match(filename, /SWPM.*\.SAR/ ) != 0) printf("      override_target_filename: \"SWPM.SAR\"\n");
    if (match(filename, /SWPM.*\.SAR/ ) != 0) printf("      extract: true\n");
    if (match(filename, /SWPM.*\.SAR/ ) != 0) printf("      extractDir: SWPM\n");
    if ( sapurl != "" ) printf("      url: https://softwaredownloads.sap.com/file/%s\n", sapurl);
    if ( current == "CC" ) printf("      download: false\n");
    if ( current != "CC" ) printf("      path: download_basket\n");
  }

  stackfileid = gensub(/^MP_Excel_([0-9]+_[0-9]+).*/, "\\1", "g", xlsfile);
  printf("\n  templates:\n    - name: \"%s ini file\"\n      file: \"%s.inifile.params\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", product, product);
  printf("\n  stackfiles:");
  printf("\n    - name: \"Download Basket JSON Manifest\"\n      file: \"%s\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", jsonfile);
  printf("\n    - name: \"Download Basket Spreadsheet\"\n      file: \"%s\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", xlsfile);
  printf("\n    - name: \"Download Basket Plan\"\n      file: \"MP_Plan_%s_.pdf\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", stackfileid);
  printf("\n    - name: \"Download Basket Stack text\"\n      file: \"MP_Stack_%s_.txt\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", stackfileid);
  printf("\n    - name: \"Download Basket Stack text\"\n      file: \"MP_Stack_%s_.txt\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", stackfileid);
  printf("\n    - name: \"Download Basket Stack XML\"\n      file: \"%s\"\n      override_target_location: \"{{ target_media_location }}/config\"\n", xmlfile);
  printf("\n    - name: \"Download Basket permalinks\"\n      file: \"myDownloadBasketFiles.txt\"\n      override_target_location: \"{{ target_media_location }}/config\"\n");
  printf("\n...\n");
}
'


