#!/usr/bin/env python3
"""
Advanced HANA VM Configuration Parser

This module handles the complex parsing of Microsoft Azure documentation
to extract VM sizing information for SAP HANA.

For the actual VM configuration data, see hana_vm_configurations.py
"""

import re
from typing import Dict, List, Optional, Tuple
import logging

logger = logging.getLogger(__name__)

class AzureDocumentationParser:
    """Advanced parser for Azure SAP HANA documentation"""
    
    def __init__(self):
        self.vm_data_patterns = {
            # Patterns to match different VM configuration formats
            'data_volume': r'Configuration for SAP \/hana\/data volume:',
            'log_volume': r'Configuration for SAP \/hana\/log volume:',
            'other_volumes': r'For the other volumes, the configuration would look like:',
            'vm_row': r'^([ME]\d+[a-z_\d]*)\s*\|\s*(\d+)\s*GiB\s*\|\s*(\d+(?:,\d+)?)\s*MBps\s*\|\s*([^|]+)\s*\|',
        }
        
    def extract_tables_from_text(self, text: str) -> List[Dict]:
        """Extract table data from the fetched text"""
        configurations = []
        
        # Split the text by sections
        sections = self._split_into_sections(text)
        
        for section_name, section_content in sections.items():
            logger.info(f"Processing section: {section_name}")
            configs = self._extract_vm_configs_from_section(section_content)
            configurations.extend(configs)
        
        return configurations
    
    def _split_into_sections(self, text: str) -> Dict[str, str]:
        """Split text into different configuration sections"""
        sections = {}
        
        # Find data volume section
        data_match = re.search(r'Configuration for SAP /hana/data volume:(.*?)(?=Configuration for|For the|$)', 
                              text, re.DOTALL | re.IGNORECASE)
        if data_match:
            sections['data_volume'] = data_match.group(1)
        
        # Find log volume section  
        log_match = re.search(r'Configuration for SAP /hana/log volume:(.*?)(?=For the other volumes|$)',
                             text, re.DOTALL | re.IGNORECASE)
        if log_match:
            sections['log_volume'] = log_match.group(1)
        
        # Find other volumes section
        other_match = re.search(r'For the other volumes, the configuration would look like:(.*?)(?=Check whether|$)',
                               text, re.DOTALL | re.IGNORECASE)
        if other_match:
            sections['other_volumes'] = other_match.group(1)
            
        return sections
    
    def _extract_vm_configs_from_section(self, section_text: str) -> List[Dict]:
        """Extract VM configurations from a section of text"""
        configs = []
        lines = section_text.split('\n')
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('|'):
                continue
                
            # Try to match VM configuration patterns
            vm_match = re.match(r'^([ME]\d+[a-z_\(\)\d]*)\s*\|\s*(\d+(?:,\d+)?)\s*GiB\s*\|\s*(\d+(?:,\d+)?)\s*MBps\s*\|\s*(.+)$', line)
            
            if vm_match:
                vm_name = vm_match.group(1).strip()
                memory = vm_match.group(2).replace(',', '')
                throughput = vm_match.group(3).replace(',', '')
                disk_config = vm_match.group(4).strip()
                
                # Clean up VM name
                vm_name = re.sub(r'\([^)]*\)', '', vm_name)  # Remove parentheses content
                vm_name = vm_name.replace(' ', '').replace(',', '')
                
                if vm_name and memory.isdigit() and throughput.isdigit():
                    config = {
                        'vm_name': vm_name,
                        'memory_gb': int(memory),
                        'throughput_mbps': int(throughput),
                        'disk_config': disk_config
                    }
                    configs.append(config)
                    logger.debug(f"Parsed VM config: {config}")
        
        return configs

    def parse_disk_specification(self, disk_spec: str) -> Dict:
        """Parse disk specification like '4 x P10' into structured format"""
        disk_info = {
            'count': 1,
            'disk_type': 'P10',
            'size_gb': 128,
            'premium': True
        }
        
        # Match patterns like "4 x P10" or "3 x P15" 
        match = re.search(r'(\d+)\s*x\s*([PE]\d+)', disk_spec)
        if match:
            disk_info['count'] = int(match.group(1))
            disk_type_code = match.group(2)
            disk_info['disk_type'] = disk_type_code
            disk_info['premium'] = disk_type_code.startswith('P')
            
            # Map disk type to size
            disk_sizes = {
                'P6': 64, 'P10': 128, 'P15': 256, 'P20': 512, 'P30': 1024, 'P40': 2048, 
                'P50': 4096, 'P60': 8192, 'P70': 16384, 'P80': 32768,
                'E6': 64, 'E10': 128, 'E15': 256, 'E20': 512, 'E30': 1024, 'E40': 2048,
                'E50': 4096, 'E60': 8192, 'E70': 16384, 'E80': 32768
            }
            disk_info['size_gb'] = disk_sizes.get(disk_type_code, 128)
        
        return disk_info
