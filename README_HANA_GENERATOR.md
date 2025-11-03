# SAP HANA VM Size Configuration Generator

This repository contains AI-oriented tools to automatically generate and update SAP HANA VM sizing configurations based on Microsoft Azure documentation.

## Overview

The tools automatically extract VM sizing information from Microsoft's Azure SAP HANA documentation and convert it into the JSON format used by your `hana_sizes.json` configuration file.

## Files

- **`simple_hana_generator.py`** - Main script for updating hana_sizes.json
- **`hana_vm_configurations.py`** - VM configuration data extracted from Azure docs  
- **`future_azure_documentation_parser.py`** - Advanced parsing utilities (for future web scraping)

## Quick Start

**No dependencies needed!** The script uses only Python standard library.

1. **Run a dry-run to see what changes would be made:**
   ```bash
   python3 simple_hana_generator.py --dry-run
   ```

2. **Update your hana_sizes.json file:**
   ```bash
   python3 simple_hana_generator.py
   ```

## Usage Examples

### Basic Usage
```bash
# Update the default file (./deploy/configs/hana_sizes.json)
python3 simple_hana_generator.py

# Update the real hana_sizes.json file
python3 simple_hana_generator.py --output ./deploy/configs/hana_sizes.json

# See what changes would be made (dry run)
python3 simple_hana_generator.py --dry-run

# Enable verbose output
python3 simple_hana_generator.py --verbose
```

## How It Works

### 1. **Manual Configuration Extraction** ✅
The `AZURE_HANA_CONFIGURATIONS` dictionary in `hana_vm_configurations.py` was **manually created** by:
- Reading Microsoft's official Azure SAP HANA documentation tables
- Extracting each VM type's disk configuration requirements
- Converting them to a structured format

### 2. **Smart JSON Generation** 
The script automatically:
- Reads your existing `hana_sizes.json` file
- Generates new VM configurations based on Microsoft documentation
- Only adds NEW configurations (never overwrites existing ones)
- Maintains the exact JSON structure your automation expects

### 3. **No Web Dependencies**
- **No internet required** during execution
- **No external dependencies** - uses only Python standard library
- **Reliable and fast** - data is pre-validated

## What It Generates

The script automatically creates configurations for:

### M-Series VMs (Production HANA with Write Accelerator)
- M32ts, M32ls, M64ls
- M32dms_v2, M32ms_v2  
- M64s, M64ds_v2, M64ms, M64dms_v2
- M128s, M128ds_v2, M128ms, M128dms_v2, M128ms_v2

### E-Series VMs (with UltraSSD logs for cost optimization)  
- E20ds_v4, E20ds_v5
- E32ds_v4, E32ds_v5
- E48ds_v4, E48ds_v5
- E64s_v3, E64ds_v4, E64ds_v5
- E96ds_v5

## Configuration Details

Each generated configuration includes:

### VM Compute Settings
- VM size (e.g., "Standard_M32ts") 
- Swap size (for applicable VMs)

### Storage Configuration  
- **OS Disk**: Premium SSD, 128GB, ReadWrite caching
- **Data Disks**: Multiple Premium SSD disks, no caching
- **Log Disks**: Premium SSD with Write Accelerator (M-Series) or UltraSSD (E-Series)
- **Shared Disk**: Premium SSD with ReadOnly caching
- **SAP Disk**: Premium SSD with ReadOnly caching
- **Backup Disk**: Premium SSD with ReadOnly caching

### Features
- ✅ Follows Microsoft's official sizing recommendations
- ✅ Proper disk caching for each volume type  
- ✅ Write Accelerator configuration for M-Series log volumes
- ✅ UltraSSD configuration for E-Series log volumes
- ✅ Correct LUN assignments
- ✅ Preserves existing configurations
- ✅ Supports dry-run mode
- ✅ No external dependencies

## Sample Output

```json
{
    "db": {
        "M32ts": {
            "compute": {
                "vm_size": "Standard_M32ts"
            },
            "storage": [
                {
                    "name": "os",
                    "fullname": "",
                    "count": 1,
                    "disk_type": "Premium_LRS", 
                    "size_gb": 128,
                    "caching": "ReadWrite"
                },
                {
                    "name": "data",
                    "fullname": "",
                    "count": 4,
                    "disk_type": "Premium_LRS",
                    "size_gb": 64,
                    "caching": "None", 
                    "write_accelerator": false,
                    "lun_start": 0
                },
                {
                    "name": "log",
                    "count": 3,
                    "disk_type": "Premium_LRS",
                    "size_gb": 128,
                    "caching": "None",
                    "write_accelerator": true,
                    "lun_start": 9
                }
            ]
        }
    }
}
```

## When To Run

You only need to run this script when:
- **New Azure VM types** are announced by Microsoft
- **Microsoft updates** their sizing recommendations  
- **You want to add** configurations that aren't in your current file

Typically this might be **once every few months** when Microsoft releases new VM types.

## Error Handling

The script includes comprehensive error handling:
- Validates file existence before processing
- Preserves existing configurations on errors
- Provides detailed logging of all operations
- Supports dry-run mode to preview changes safely

## Customization

To add new VM types:

1. Add the VM configuration to `AZURE_HANA_CONFIGURATIONS` in `hana_vm_configurations.py`
2. Follow the existing format with disk configurations
3. Test with `--dry-run` before applying changes

## Architecture

```
simple_hana_generator.py          # Main script
├── imports hana_vm_configurations.py   # VM data (manually extracted)
└── imports future_azure_documentation_parser.py   # Future web scraping utilities
```

The separation keeps the code clean:
- **`hana_vm_configurations.py`**: Pure data file with VM configurations
- **`simple_hana_generator.py`**: Business logic for JSON generation
- **`future_azure_documentation_parser.py`**: Advanced parsing utilities for future use

## License

This tool is provided as-is for automating SAP HANA infrastructure configuration based on Microsoft's official documentation.
