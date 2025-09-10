#!/usr/bin/env python3
"""
SAP HANA VM Size Configuration Generator

This script generates SAP HANA VM sizing configurations based on Microsoft Azure 
documentation and updates the hana_sizes.json file automatically.

Usage:
    python3 simple_hana_generator.py [--output OUTPUT] [--dry-run]
"""

import json
import argparse
import logging
import sys
import os
from typing import Dict, List, Optional
from hana_vm_configurations import AZURE_HANA_CONFIGURATIONS, DISK_SIZE_MAPPING, LUN_MAPPING

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimpleHanaConfigGenerator:
    """Simple and reliable HANA configuration generator"""
    
    def __init__(self):
        # Use imported constants from hana_vm_configurations
        self.disk_size_mapping = DISK_SIZE_MAPPING
        self.lun_mapping = LUN_MAPPING
        
    def parse_disk_config(self, config_str: str, disk_name: str) -> Optional[Dict]:
        """Parse disk configuration string and return JSON format"""
        import re
        
        # Handle UltraSSD special case
        if 'UltraSSD' in config_str:
            size_match = re.search(r'(\d+)GB', config_str)
            size_gb = int(size_match.group(1)) if size_match else 128
            
            disk_config = {
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
            
            # Remove fullname for log disks
            if disk_name != "log":
                disk_config["fullname"] = ""
                
            return disk_config
        
        # Parse regular disk configuration like "4 x P10"
        match = re.match(r'(\d+)\s*x\s*([PE]\d+)', config_str.strip())
        if not match:
            logger.warning(f"Could not parse disk config: {config_str}")
            return None
            
        count = int(match.group(1))
        disk_type_code = match.group(2)
        
        # Determine disk type and size
        disk_type = "Premium_LRS" if disk_type_code.startswith('P') else "StandardSSD_LRS"
        size_gb = self.disk_size_mapping.get(disk_type_code, 128)
        
        # Set caching based on disk name
        caching_map = {
            'os': 'ReadWrite',
            'data': 'None',
            'log': 'None', 
            'shared': 'ReadOnly',
            'sap': 'ReadOnly',
            'backup': 'ReadOnly'
        }
        
        disk_config = {
            "name": disk_name,
            "count": count,
            "disk_type": disk_type,
            "size_gb": size_gb,
            "caching": caching_map.get(disk_name, "ReadOnly"),
            "write_accelerator": disk_name == "log" and disk_type == "Premium_LRS",
            "lun_start": self.lun_mapping.get(disk_name, 0)
        }
        
        # Add fullname for most disks (but not log)
        if disk_name != "log":
            disk_config["fullname"] = ""
            
        return disk_config
    
    def create_vm_configuration(self, vm_name: str, config_data: Dict) -> Dict:
        """Create complete VM configuration in target JSON format"""
        
        # Start with compute configuration
        compute_config = {"vm_size": f"Standard_{vm_name}"}
        
        # Add swap size if specified
        if "swap_size_gb" in config_data:
            compute_config["swap_size_gb"] = config_data["swap_size_gb"]
            
        storage_configs = []
        
        # OS disk (standard across all VMs)
        os_disk = {
            "name": "os",
            "fullname": "",
            "count": 1,
            "disk_type": "Premium_LRS",
            "size_gb": 128,
            "caching": "ReadWrite"
        }
        storage_configs.append(os_disk)
        
        # Data disks
        if "data_config" in config_data:
            data_config = self.parse_disk_config(config_data["data_config"], "data")
            if data_config:
                storage_configs.append(data_config)
        
        # Log disks
        if "log_config" in config_data:
            log_config = self.parse_disk_config(config_data["log_config"], "log")
            if log_config:
                storage_configs.append(log_config)
        
        # Shared disk
        if "shared_config" in config_data:
            shared_config = self.parse_disk_config(config_data["shared_config"], "shared")
            if shared_config:
                storage_configs.append(shared_config)
        
        # SAP disk 
        if "sap_config" in config_data:
            sap_config = self.parse_disk_config(config_data["sap_config"], "sap")
            if sap_config:
                storage_configs.append(sap_config)
        
        # Backup disk
        if "backup_config" in config_data:
            backup_config = self.parse_disk_config(config_data["backup_config"], "backup")
            if backup_config:
                storage_configs.append(backup_config)
        
        return {
            "compute": compute_config,
            "storage": storage_configs
        }
    
    def generate_all_configurations(self) -> Dict[str, Dict]:
        """Generate all VM configurations from the documentation data"""
        configurations = {}
        
        logger.info("Generating configurations from Azure documentation data...")
        
        for vm_name, config_data in AZURE_HANA_CONFIGURATIONS.items():
            try:
                vm_config = self.create_vm_configuration(vm_name, config_data)
                configurations[vm_name] = vm_config
                logger.debug(f"Generated configuration for {vm_name}")
            except Exception as e:
                logger.error(f"Failed to generate configuration for {vm_name}: {e}")
                continue
        
        logger.info(f"Successfully generated {len(configurations)} VM configurations")
        return configurations
    
    def update_hana_sizes_file(self, file_path: str, dry_run: bool = False) -> None:
        """Update the hana_sizes.json file with new configurations"""
        try:
            # Check if file exists
            if not os.path.exists(file_path):
                logger.error(f"File {file_path} does not exist")
                sys.exit(1)
                
            # Load existing configuration
            with open(file_path, 'r') as f:
                existing_config = json.load(f)
            
            logger.info(f"Loaded existing configuration from {file_path}")
            
            # Generate new configurations
            new_configs = self.generate_all_configurations()
            
            # Ensure db section exists
            if 'db' not in existing_config:
                existing_config['db'] = {}
            
            # Track what we're adding
            added_configs = []
            updated_configs = []
            
            for vm_name, vm_config in new_configs.items():
                if vm_name in existing_config['db']:
                    updated_configs.append(vm_name)
                    if not dry_run:
                        existing_config['db'][vm_name] = vm_config
                else:
                    added_configs.append(vm_name)
                    if not dry_run:
                        existing_config['db'][vm_name] = vm_config
            
            # Report what would be or was changed
            if dry_run:
                logger.info("=== DRY RUN - Changes that would be made ===")
                if added_configs:
                    logger.info(f"Would ADD {len(added_configs)} new configurations:")
                    for vm in added_configs:
                        logger.info(f"  + {vm}")
                
                if updated_configs:
                    logger.info(f"Would UPDATE {len(updated_configs)} existing configurations:")
                    for vm in updated_configs:
                        logger.info(f"  ~ {vm}")
                        
                if not added_configs and not updated_configs:
                    logger.info("No changes would be made")
                    
                logger.info("Use without --dry-run to apply these changes")
                return
            
            # Write the updated configuration
            with open(file_path, 'w') as f:
                json.dump(existing_config, f, indent=4)
            
            # Report what was actually changed  
            logger.info("=== Configuration Updated Successfully ===")
            if added_configs:
                logger.info(f"ADDED {len(added_configs)} new configurations:")
                for vm in added_configs:
                    logger.info(f"  + {vm}")
            
            if updated_configs:
                logger.info(f"UPDATED {len(updated_configs)} existing configurations:")
                for vm in updated_configs:
                    logger.info(f"  ~ {vm}")
                    
            if not added_configs and not updated_configs:
                logger.info("No changes were made - all configurations already up to date")
            
            logger.info(f"Configuration file updated: {file_path}")
            
        except Exception as e:
            logger.error(f"Failed to update hana sizes file: {e}")
            sys.exit(1)

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="SAP HANA VM Size Configuration Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Update the default hana_sizes.json file
  python3 simple_hana_generator.py
  
  # Update a specific file
  python3 simple_hana_generator.py --output /path/to/hana_sizes.json
  
  # See what changes would be made (dry run)
  python3 simple_hana_generator.py --dry-run
  
  # Enable verbose output
  python3 simple_hana_generator.py --verbose
        """
    )
    
    parser.add_argument(
        '--output', '-o',
        default='./deploy/configs/hana_sizes.json',
        help='Path to hana_sizes.json file to update (default: %(default)s)'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what changes would be made without updating the file'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose logging'
    )
    
    args = parser.parse_args()
    
    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Initialize generator and update file
    generator = SimpleHanaConfigGenerator()
    generator.update_hana_sizes_file(
        file_path=args.output,
        dry_run=args.dry_run
    )

if __name__ == "__main__":
    main()
