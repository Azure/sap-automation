#!/usr/bin/env python3
"""
Azure SAP HANA VM Configurations

This file contains the manually extracted VM sizing configurations from Microsoft's
official Azure SAP HANA documentation:
https://learn.microsoft.com/en-us/azure/sap/workloads/hana-vm-premium-ssd-v1

Each configuration includes:
- Memory size in GB
- Data disk configuration (e.g., "4 x P10" = 4 Premium P10 disks)
- Log disk configuration 
- Shared disk configuration
- SAP disk configuration
- Backup disk configuration
- Optional swap size for certain VMs

Last updated: Based on Microsoft documentation as of September 2025
"""

# Azure SAP HANA VM configurations extracted from Microsoft documentation
AZURE_HANA_CONFIGURATIONS = {
    # M-Series VMs - Production configurations with Write Accelerator support
    "M32ts": {
        "memory_gb": 192,
        "data_config": "4 x P6",
        "log_config": "3 x P10", 
        "shared_config": "1 x P15",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M32ls": {
        "memory_gb": 256,
        "data_config": "4 x P6",
        "log_config": "3 x P10",
        "shared_config": "1 x P15", 
        "sap_config": "1 x P6",
        "backup_config": "1 x P6",
        "swap_size_gb": 2
    },
    "M64ls": {
        "memory_gb": 512,
        "data_config": "4 x P10",
        "log_config": "3 x P10",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6", 
        "backup_config": "1 x P6",
        "swap_size_gb": 2
    },
    "M32dms_v2": {
        "memory_gb": 875,
        "data_config": "4 x P15",
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M32ms_v2": {
        "memory_gb": 875,
        "data_config": "4 x P15", 
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64s": {
        "memory_gb": 1024,
        "data_config": "4 x P15",
        "log_config": "3 x P15", 
        "shared_config": "1 x P30",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64ds_v2": {
        "memory_gb": 1024,
        "data_config": "4 x P15",
        "log_config": "3 x P15",
        "shared_config": "1 x P30", 
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64ms": {
        "memory_gb": 1792,
        "data_config": "4 x P20",
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64dms_v2": {
        "memory_gb": 1792,
        "data_config": "4 x P20", 
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M128s": {
        "memory_gb": 2048,
        "data_config": "4 x P20",
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128ds_v2": {
        "memory_gb": 2048,
        "data_config": "4 x P20", 
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128ms": {
        "memory_gb": 3892,
        "data_config": "4 x P30",
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128dms_v2": {
        "memory_gb": 3892,
        "data_config": "4 x P30",
        "log_config": "3 x P15", 
        "shared_config": "1 x P30",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128ms_v2": {
        "memory_gb": 3892,
        "data_config": "4 x P30",
        "log_config": "3 x P15",
        "shared_config": "1 x P30",
        "sap_config": "1 x P10", 
        "backup_config": "1 x P6"
    },
    
    # E-Series VMs with UltraSSD for logs (cost-effective for smaller workloads)
    "E20ds_v4": {
        "memory_gb": 160,
        "data_config": "3 x P10",
        "log_config": "UltraSSD 80GB",
        "shared_config": "1 x P15",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E20ds_v5": {
        "memory_gb": 160,
        "data_config": "3 x P10", 
        "log_config": "UltraSSD 80GB",
        "shared_config": "1 x P15",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E32ds_v4": {
        "memory_gb": 256,
        "data_config": "3 x P10",
        "log_config": "UltraSSD 128GB",
        "shared_config": "1 x P15",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E32ds_v5": {
        "memory_gb": 256,
        "data_config": "3 x P10",
        "log_config": "UltraSSD 128GB", 
        "shared_config": "1 x P15",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E48ds_v4": {
        "memory_gb": 384,
        "data_config": "3 x P15",
        "log_config": "UltraSSD 192GB",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E48ds_v5": {
        "memory_gb": 384,
        "data_config": "3 x P15",
        "log_config": "UltraSSD 192GB",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6", 
        "backup_config": "1 x P6"
    },
    "E64s_v3": {
        "memory_gb": 432,
        "data_config": "3 x P15",
        "log_config": "UltraSSD 220GB",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E64ds_v4": {
        "memory_gb": 504,
        "data_config": "3 x P15",
        "log_config": "UltraSSD 256GB",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E64ds_v5": {
        "memory_gb": 512,
        "data_config": "3 x P15", 
        "log_config": "UltraSSD 256GB",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E96ds_v5": {
        "memory_gb": 672,
        "data_config": "3 x P15",
        "log_config": "UltraSSD 256GB",
        "shared_config": "1 x P20",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    }
}

# Mapping of disk type codes to sizes (in GB)
DISK_SIZE_MAPPING = {
    # Premium SSD disk sizes
    'P6': 64, 'P10': 128, 'P15': 256, 'P20': 512, 'P30': 1024, 
    'P40': 2048, 'P50': 4096, 'P60': 8192, 'P70': 16384, 'P80': 32768,
    
    # Standard SSD disk sizes  
    'E6': 64, 'E10': 128, 'E15': 256, 'E20': 512, 'E30': 1024, 
    'E40': 2048, 'E50': 4096, 'E60': 8192, 'E70': 16384, 'E80': 32768
}

# LUN start positions for different disk types
LUN_MAPPING = {
    'data': 0,
    'shared': 6,
    'log': 9,
    'sap': 14,
    'backup': 15
}
