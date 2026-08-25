# Media symptom map

| Observed symptom | Operator check |
| --- | --- |
| `sap-parameters.yaml` missing | Run from the SAP-system directory and confirm generated files exist. |
| `BOM_CATALOG` missing or invalid | Point it at the samples root containing `SAP/` and `BOM/`. |
| BOM not found | Recheck the four BOM keys and matching sample names. |
| SAP download credentials missing | Restore approved credentials; do not keep retrying. |
| Storage authentication failure | Confirm the intended storage account, container, and authentication method. |
| Archive `404` | Compare the selected BOM archive name with the library and download output. |
| Checksum mismatch | Compare the reviewed BOM checksum with the actual archive; never invent a checksum. |
| `SAPCAR`, `.SAR`, or `.EXE` extraction failure | Preserve stderr and verify the archive named by the BOM. |
| BOM processing incomplete | Review the first failed processing step and its documented completion evidence. |

Use `docs/local/06-00-software-and-installation.md` and
`docs/local/troubleshooting.md`. If the signature is not documented, stop
rather than infer an internal recovery path.
