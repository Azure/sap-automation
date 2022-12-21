#!/bin/bash

# ansible-playbook                                                                                                \
#   --inventory   new-hosts.yaml                                                                                  \
#   --user        azureadm                                                                                        \
#   --private-key sshkey                                                                                          \
#   --extra-vars="@sap-parameters.yaml"                                                                           \
# playbook_00_transition_start_for_sap_install.yaml                                                               

# test BOMs
                  # "bom_base_name":                  "TEST_BOM_v0001ms",
                  # "bom_base_name":                  "TEST_BOM_v0002ms",


set -x

ansible-playbook                                                                                                \
  --extra-vars='{
                  "bom_base_name":                  "TEST_BOM_v0002ms",
                  "new_bom_name":                   "MKD_v0001cust",
                  "download_directory":             "~/tmp/download",
                  "sapbits_location_base_path":     "https://mkddynbomtst.blob.core.windows.net/sapbits"
                }'                                                                                              \
  --extra-vars="@../../../SUSER.yaml"                                                                           \
  -v                                                                                                            \
test_playbook_bom_downloader.yaml

set +x

# S41909SPS03_v0001ms
# ansible-playbook                                                                                                \
#   --extra-vars='{
#                   "bom_base_name":                  "TEST_BOM_v0001ms",
#                   "download_directory":             "https://mkdb0eus2saplibb76.blob.core.windows.net/sapbits",
#                   "sapbits_bom_files":              "sapfiles",
#                   "target_media_location":          "/usr/sap/install",
#                   "kv_name":                        "NOT_SET",
#                   "download_directory":             "~/GIT/test/mnt/download"
#                 }'                                                                                              \
#   --extra-vars="@../../../SUSER.yaml"                                                                           \
# test_playbook_bom_downloader.yaml


# Local Download Only
#                   "bom_base_name":                  "TEST_BOM_v0002ms",
#                   "download_directory":             "~/tmp/download"


# Download with SA
#                   "bom_base_name":                  "TEST_BOM_v0002ms",
#                   "download_directory":             "~/tmp/download",
#                   "sapbits_location_base_path":     "https://mkddynbomtst.blob.core.windows.net/sapbits",
