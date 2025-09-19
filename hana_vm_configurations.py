#!/usr/bin/env python3
"""
Azure SAP HANA VM Configurations

This file contains the manually extracted VM sizing configurations from Microsoft's
official Azure SAP HANA documentation:
- Premium SSD v1: https://learn.microsoft.com/en-us/azure/sap/workloads/hana-vm-premium-ssd-v1
- Premium SSD v2: https://learn.microsoft.com/en-us/azure/sap/workloads/hana-vm-premium-ssd-v2

Each configuration includes:
- Memory size in GB
- Data disk configuration (e.g., "4 x P10" = 4 Premium P10 disks, or "PremiumV2 1024GB 425MBps 3000IOPS")
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
    },

    # Premium SSD v2 configurations - Memory-based sizing
    # Configurations based on VM memory tiers as per Microsoft documentation
    # Data: Size = 1.2 x VM memory, Log: Size = 0.5 x VM memory (or 500GB if VM > 1TB)
    # Shared: Size = 1 x VM memory (or 1TB if VM > 1TB)
    
    # Below 1TB memory - 425 MBps data, 275 MBps log, 3000 IOPS each
    "E20ds_v4_v2": {
        "memory_gb": 160,
        "data_config": "PremiumV2 192GB 425MBps 3000IOPS",  # 1.2 x 160GB
        "log_config": "PremiumV2 80GB 275MBps 3000IOPS",    # 0.5 x 160GB
        "shared_config": "PremiumV2 160GB 125MBps 3000IOPS", # 1 x 160GB (default IOPS/throughput)
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E20ds_v5_v2": {
        "memory_gb": 160,
        "data_config": "PremiumV2 192GB 425MBps 3000IOPS",
        "log_config": "PremiumV2 80GB 275MBps 3000IOPS",
        "shared_config": "PremiumV2 160GB 125MBps 3000IOPS",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E32ds_v4_v2": {
        "memory_gb": 256,
        "data_config": "PremiumV2 307GB 425MBps 3000IOPS",  # 1.2 x 256GB
        "log_config": "PremiumV2 128GB 275MBps 3000IOPS",   # 0.5 x 256GB
        "shared_config": "PremiumV2 256GB 125MBps 3000IOPS", # 1 x 256GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E32ds_v5_v2": {
        "memory_gb": 256,
        "data_config": "PremiumV2 307GB 425MBps 3000IOPS",
        "log_config": "PremiumV2 128GB 275MBps 3000IOPS",
        "shared_config": "PremiumV2 256GB 125MBps 3000IOPS",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E48ds_v4_v2": {
        "memory_gb": 384,
        "data_config": "PremiumV2 461GB 425MBps 3000IOPS",  # 1.2 x 384GB
        "log_config": "PremiumV2 192GB 275MBps 3000IOPS",   # 0.5 x 384GB
        "shared_config": "PremiumV2 384GB 125MBps 3000IOPS", # 1 x 384GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E48ds_v5_v2": {
        "memory_gb": 384,
        "data_config": "PremiumV2 461GB 425MBps 3000IOPS",
        "log_config": "PremiumV2 192GB 275MBps 3000IOPS",
        "shared_config": "PremiumV2 384GB 125MBps 3000IOPS",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E64s_v3_v2": {
        "memory_gb": 432,
        "data_config": "PremiumV2 518GB 425MBps 3000IOPS",  # 1.2 x 432GB
        "log_config": "PremiumV2 216GB 275MBps 3000IOPS",   # 0.5 x 432GB
        "shared_config": "PremiumV2 432GB 125MBps 3000IOPS", # 1 x 432GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E64ds_v4_v2": {
        "memory_gb": 504,
        "data_config": "PremiumV2 605GB 425MBps 3000IOPS",  # 1.2 x 504GB
        "log_config": "PremiumV2 252GB 275MBps 3000IOPS",   # 0.5 x 504GB
        "shared_config": "PremiumV2 504GB 125MBps 3000IOPS", # 1 x 504GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E64ds_v5_v2": {
        "memory_gb": 512,
        "data_config": "PremiumV2 614GB 425MBps 3000IOPS",  # 1.2 x 512GB
        "log_config": "PremiumV2 256GB 275MBps 3000IOPS",   # 0.5 x 512GB
        "shared_config": "PremiumV2 512GB 125MBps 3000IOPS", # 1 x 512GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "E96ds_v5_v2": {
        "memory_gb": 672,
        "data_config": "PremiumV2 806GB 425MBps 3000IOPS",  # 1.2 x 672GB
        "log_config": "PremiumV2 336GB 275MBps 3000IOPS",   # 0.5 x 672GB
        "shared_config": "PremiumV2 672GB 125MBps 3000IOPS", # 1 x 672GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },

    # 1TB to below 2TB memory - 600 MBps data, 300 MBps log
    "M32ts_v2": {
        "memory_gb": 192,
        "data_config": "PremiumV2 230GB 425MBps 3000IOPS",  # 1.2 x 192GB (still < 1TB range)
        "log_config": "PremiumV2 96GB 275MBps 3000IOPS",    # 0.5 x 192GB
        "shared_config": "PremiumV2 192GB 125MBps 3000IOPS", # 1 x 192GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M32ls_v2": {
        "memory_gb": 256,
        "data_config": "PremiumV2 307GB 425MBps 3000IOPS",  # 1.2 x 256GB
        "log_config": "PremiumV2 128GB 275MBps 3000IOPS",   # 0.5 x 256GB
        "shared_config": "PremiumV2 256GB 125MBps 3000IOPS", # 1 x 256GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6",
        "swap_size_gb": 2
    },
    "M64ls_v2": {
        "memory_gb": 512,
        "data_config": "PremiumV2 614GB 425MBps 3000IOPS",  # 1.2 x 512GB
        "log_config": "PremiumV2 256GB 275MBps 3000IOPS",   # 0.5 x 512GB
        "shared_config": "PremiumV2 512GB 125MBps 3000IOPS", # 1 x 512GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6",
        "swap_size_gb": 2
    },
    "M32dms_v2_v2": {
        "memory_gb": 875,
        "data_config": "PremiumV2 1050GB 425MBps 3000IOPS", # 1.2 x 875GB
        "log_config": "PremiumV2 438GB 275MBps 3000IOPS",   # 0.5 x 875GB
        "shared_config": "PremiumV2 875GB 125MBps 3000IOPS", # 1 x 875GB
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M32ms_v2_v2": {
        "memory_gb": 875,
        "data_config": "PremiumV2 1050GB 425MBps 3000IOPS",
        "log_config": "PremiumV2 438GB 275MBps 3000IOPS",
        "shared_config": "PremiumV2 875GB 125MBps 3000IOPS",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64s_v2": {
        "memory_gb": 1024,
        "data_config": "PremiumV2 1229GB 600MBps 5000IOPS", # 1.2 x 1024GB (now in 1TB-2TB range)
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",   # 500GB for >1TB memory
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS", # 1TB for >1TB memory
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64ds_v2_v2": {
        "memory_gb": 1024,
        "data_config": "PremiumV2 1229GB 600MBps 5000IOPS",
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64ms_v2": {
        "memory_gb": 1792,
        "data_config": "PremiumV2 2150GB 600MBps 5000IOPS", # 1.2 x 1792GB
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",   # 500GB for >1TB memory
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS", # 1TB for >1TB memory
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },
    "M64dms_v2_v2": {
        "memory_gb": 1792,
        "data_config": "PremiumV2 2150GB 600MBps 5000IOPS",
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P6",
        "backup_config": "1 x P6"
    },

    # 2TB to below 4TB memory - 800 MBps data, 300 MBps log  
    "M128s_v2": {
        "memory_gb": 2048,
        "data_config": "PremiumV2 2458GB 800MBps 12000IOPS", # 1.2 x 2048GB (now in 2TB-4TB range)
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",    # 500GB for >1TB memory
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS", # 1TB for >1TB memory
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128ds_v2_v2": {
        "memory_gb": 2048,
        "data_config": "PremiumV2 2458GB 800MBps 12000IOPS",
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128ms_v2": {
        "memory_gb": 3892,
        "data_config": "PremiumV2 4670GB 800MBps 12000IOPS", # 1.2 x 3892GB (still in 2TB-4TB range)
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",    # 500GB for >1TB memory
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS", # 1TB for >1TB memory
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128dms_v2_v2": {
        "memory_gb": 3892,
        "data_config": "PremiumV2 4670GB 800MBps 12000IOPS",
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M128ms_v2_v2": {
        "memory_gb": 3892,
        "data_config": "PremiumV2 4670GB 800MBps 12000IOPS",
        "log_config": "PremiumV2 500GB 300MBps 4000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },

    # 4TB to below 8TB memory - 1200 MBps data, 400 MBps log
    # Note: Single disk limit is 1200 MBps, larger VMs may need striping
    "M416ms_v2": {
        "memory_gb": 11400,  # 11.4TB
        "data_config": "PremiumV2 13680GB 1300MBps 25000IOPS", # 1.2 x 11400GB - special case from doc
        "log_config": "PremiumV2 500GB 400MBps 5000IOPS",      # 500GB for >1TB memory
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",  # 1TB for >1TB memory
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },

    # Larger M-series VMs - Latest generation with higher throughput
    "M624ds_12_v3": {
        "memory_gb": 11400,
        "data_config": "PremiumV2 13680GB 1300MBps 40000IOPS", # From documentation table
        "log_config": "PremiumV2 500GB 600MBps 6000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M832ds_12_v3": {
        "memory_gb": 11400,
        "data_config": "PremiumV2 13680GB 1300MBps 40000IOPS",
        "log_config": "PremiumV2 500GB 600MBps 6000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M832ixs1": {
        "memory_gb": 14902,
        "data_config": "PremiumV2 17882GB 2000MBps 40000IOPS", # From documentation table
        "log_config": "PremiumV2 500GB 600MBps 9000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M832ids_16_v3": {
        "memory_gb": 15200,
        "data_config": "PremiumV2 18240GB 4000MBps 60000IOPS", # From documentation table
        "log_config": "PremiumV2 500GB 600MBps 10000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M832ixs_v2": {
        "memory_gb": 23088,
        "data_config": "PremiumV2 27706GB 2000MBps 60000IOPS", # From documentation table
        "log_config": "PremiumV2 500GB 600MBps 10000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M896ixds_32_v3": {
        "memory_gb": 30400,
        "data_config": "PremiumV2 36480GB 2000MBps 80000IOPS", # From documentation table
        "log_config": "PremiumV2 500GB 600MBps 10000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
        "backup_config": "1 x P6"
    },
    "M1792ixds_32_v3": {
        "memory_gb": 30400,
        "data_config": "PremiumV2 36480GB 2000MBps 80000IOPS", # From documentation table
        "log_config": "PremiumV2 500GB 600MBps 10000IOPS",
        "shared_config": "PremiumV2 1024GB 125MBps 3000IOPS",
        "sap_config": "1 x P10",
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
