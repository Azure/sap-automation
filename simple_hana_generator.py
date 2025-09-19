#!/usr/bin/env python3
"""
SAP HANA VM Size Configuration Generator

Generates HANA VM sizing configs from Azure docs and updates hana_sizes.json

Usage:
    python3 simple_hana_generator.py [--output OUTPUT] [--dry-run]
"""

import json
import argparse
import logging
import sys
import os
import re
from typing import Dict, List, Optional
from hana_vm_configurations import AZURE_HANA_CONFIGURATIONS, DISK_SIZE_MAPPING, LUN_MAPPING

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimpleHanaConfigGenerator:
    """HANA config generator"""
    
    def __init__(self):
        self.disk_sizes = DISK_SIZE_MAPPING
        self.lun_mapping = LUN_MAPPING
        
    def parse_disk_config(self, config_str: str, disk_name: str) -> Optional[Dict]:
        """Parse disk config string"""
        
        # Premium SSD v2 format: "PremiumV2 1024GB 425MBps 3000IOPS"
        v2_match = re.match(r'PremiumV2\s+(\d+)GB\s+(\d+)MBps\s+(\d+)IOPS', config_str.strip())
        if v2_match:
            size_gb = int(v2_match.group(1))
            throughput = int(v2_match.group(2))
            iops = int(v2_match.group(3))
            
            config = {
                "name": disk_name,
                "count": 1,
                "disk_type": "PremiumV2_LRS",
                "size_gb": size_gb,
                "caching": "None",
                "write_accelerator": False,
                "disk_iops_read_write": iops,
                "disk_mbps_read_write": throughput,
                "lun_start": self.lun_mapping.get(disk_name, 0)
            }
            
            if disk_name != "log":
                config["fullname"] = ""
                
            return config
        
        # UltraSSD format
        if 'UltraSSD' in config_str:
            size_match = re.search(r'(\d+)GB', config_str)
            size_gb = int(size_match.group(1)) if size_match else 128
            
            config = {
                "name": disk_name,
                "count": 1,
                "disk_type": "UltraSSD_LRS",
                "size_gb": size_gb,
                "caching": "None",
                "write_accelerator": False,
                "disk_iops_read_write": 1800,
                "disk_mbps_read_write": 250,
                "lun_start": self.lun_mapping.get(disk_name, 0)
            }
            
            if disk_name != "log":
                config["fullname"] = ""
                
            return config
        
        # Regular disk config like "4 x P10"
        match = re.match(r'(\d+)\s*x\s*([PE]\d+)', config_str.strip())
        if not match:
            logger.warning(f"Could not parse disk config: {config_str}")
            return None
            
        count = int(match.group(1))
        disk_type_code = match.group(2)
        
        disk_type = "Premium_LRS" if disk_type_code.startswith('P') else "StandardSSD_LRS"
        size_gb = self.disk_sizes.get(disk_type_code, 128)
        
        # Caching settings
        caching_map = {
            'os': 'ReadWrite',
            'data': 'None',
            'log': 'None', 
            'shared': 'ReadOnly',
            'sap': 'ReadOnly',
            'backup': 'ReadOnly'
        }
        
        config = {
            "name": disk_name,
            "count": count,
            "disk_type": disk_type,
            "size_gb": size_gb,
            "caching": caching_map.get(disk_name, "ReadOnly"),
            "write_accelerator": disk_name == "log" and disk_type == "Premium_LRS",
            "lun_start": self.lun_mapping.get(disk_name, 0)
        }
        
        if disk_name != "log":
            config["fullname"] = ""
            
        return config
    
    def create_vm_configuration(self, vm_name: str, config_data: Dict) -> Dict:
        """Create VM config in target JSON format"""
        
        compute_config = {"vm_size": f"Standard_{vm_name}"}
        
        if "swap_size_gb" in config_data:
            compute_config["swap_size_gb"] = config_data["swap_size_gb"]
            
        storage_configs = []
        
        # OS disk
        os_disk = {
            "name": "os",
            "fullname": "",
            "count": 1,
            "disk_type": "Premium_LRS",
            "size_gb": 128,
            "caching": "ReadWrite"
        }
        storage_configs.append(os_disk)
        
        # Parse all the different disk types
        disk_types = ["data_config", "log_config", "shared_config", "sap_config", "backup_config"]
        disk_names = ["data", "log", "shared", "sap", "backup"]
        
        for disk_type, disk_name in zip(disk_types, disk_names):
            if disk_type in config_data:
                disk_config = self.parse_disk_config(config_data[disk_type], disk_name)
                if disk_config:
                    storage_configs.append(disk_config)
        
        return {
            "compute": compute_config,
            "storage": storage_configs
        }
    
    def generate_all_configurations(self) -> Dict[str, Dict]:
        """Generate all VM configs from the Azure docs data"""
        configs = {}
        
        logger.info("Generating configs from Azure documentation...")
        
        for vm_name, config_data in AZURE_HANA_CONFIGURATIONS.items():
            try:
                vm_config = self.create_vm_configuration(vm_name, config_data)
                configs[vm_name] = vm_config
                logger.debug(f"Generated config for {vm_name}")
            except Exception as e:
                logger.error(f"Failed to generate config for {vm_name}: {e}")
                continue
        
        logger.info(f"Generated {len(configs)} VM configurations")
        return configs
    
    def update_hana_sizes_file(self, file_path: str, dry_run: bool = False):
        """Update hana_sizes.json with new configs"""
        try:
            # Load existing file or create new
            if not os.path.exists(file_path):
                logger.warning(f"File {file_path} doesn't exist, creating new one")
                existing_config = {"db": {}}
            else:
                with open(file_path, 'r') as f:
                    existing_config = json.load(f)
            
            logger.info(f"Loaded config from {file_path}")
            
            # Generate new configs
            new_configs = self.generate_all_configurations()
            
            if 'db' not in existing_config:
                existing_config['db'] = {}
            
            # Track changes
            added = []
            updated = []
            
            for vm_name, vm_config in new_configs.items():
                if vm_name in existing_config['db']:
                    updated.append(vm_name)
                else:
                    added.append(vm_name)
                
                existing_config['db'][vm_name] = vm_config
            
            # Show what's happening
            if dry_run:
                logger.info("=== DRY RUN - Changes that would be made ===")
                if added:
                    logger.info(f"Would ADD {len(added)} new configs:")
                    for vm in added:
                        logger.info(f"  + {vm}")
                
                if updated:
                    logger.info(f"Would UPDATE {len(updated)} existing configs:")
                    for vm in updated:
                        logger.info(f"  ~ {vm}")
                        
                if not added and not updated:
                    logger.info("No changes needed")
                    
                logger.info("Use without --dry-run to apply changes")
                return existing_config
            
            # Actually write the file
            with open(file_path, 'w') as f:
                json.dump(existing_config, f, indent=4)
            
            # Report what happened
            logger.info("=== Config Updated ===")
            if added:
                logger.info(f"ADDED {len(added)} new configs:")
                for vm in added:
                    logger.info(f"  + {vm}")
            
            if updated:
                logger.info(f"UPDATED {len(updated)} existing configs:")
                for vm in updated:
                    logger.info(f"  ~ {vm}")
                    
            if not added and not updated:
                logger.info("No changes made - everything up to date")
            
            logger.info(f"Updated file: {file_path}")
            return existing_config
            
        except Exception as e:
            logger.error(f"Failed to update file: {e}")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description="SAP HANA VM Configuration Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 simple_hana_generator.py
  python3 simple_hana_generator.py --output /path/to/hana_sizes.json
  python3 simple_hana_generator.py --dry-run
  python3 simple_hana_generator.py --verbose
        """
    )
    
    parser.add_argument('--output', '-o',
        default='./deploy/configs/hana_sizes.json',
        help='Path to hana_sizes.json file (default: %(default)s)')
    
    parser.add_argument('--dry-run',
        action='store_true',
        help='Show changes without updating file')
    
    parser.add_argument('--verbose', '-v',
        action='store_true',
        help='Verbose output')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    generator = SimpleHanaConfigGenerator()
    generator.update_hana_sizes_file(args.output, args.dry_run)

if __name__ == "__main__":
    main()
