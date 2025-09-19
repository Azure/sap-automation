#!/usr/bin/env python3
"""
Unit tests for SimpleHanaConfigGenerator

Tests the core functionality of the HANA VM configuration generator.
"""

import pytest
import json
import tempfile
import os
import sys
from unittest.mock import patch, mock_open

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from simple_hana_generator import SimpleHanaConfigGenerator


class TestSimpleHanaConfigGenerator:
    """Test cases for SimpleHanaConfigGenerator class"""
    
    def setup_method(self):
        """Set up test fixtures before each test method"""
        self.generator = SimpleHanaConfigGenerator()
        
        # Sample VM configuration data for testing
        self.sample_config_data = {
            "memory_gb": 192,
            "data_config": "4 x P6",
            "log_config": "3 x P10", 
            "shared_config": "1 x P15",
            "sap_config": "1 x P6",
            "backup_config": "1 x P6"
        }
        
        # Sample existing hana_sizes.json content
        self.sample_existing_config = {
            "db": {
                "Default": {
                    "compute": {
                        "vm_size": "Standard_D8s_v3"
                    },
                    "storage": [
                        {
                            "name": "os",
                            "fullname": "",
                            "count": 1,
                            "disk_type": "Premium_LRS",
                            "size_gb": 128,
                            "caching": "ReadWrite"
                        }
                    ]
                }
            }
        }

    def test_disk_size_mapping_initialization(self):
        """Test that disk size mapping is properly initialized"""
        assert 'P6' in self.generator.disk_sizes
        assert self.generator.disk_sizes['P6'] == 64
        assert self.generator.disk_sizes['P10'] == 128
        assert self.generator.disk_sizes['P30'] == 1024

    def test_lun_mapping_initialization(self):
        """Test that LUN mapping is properly initialized"""
        assert self.generator.lun_mapping['data'] == 0
        assert self.generator.lun_mapping['log'] == 9
        assert self.generator.lun_mapping['shared'] == 6

    def test_parse_premium_disk_config(self):
        """Test parsing of Premium SSD disk configuration"""
        result = self.generator.parse_disk_config("4 x P10", "data")
        
        expected = {
            "name": "data",
            "fullname": "",
            "count": 4,
            "disk_type": "Premium_LRS",
            "size_gb": 128,
            "caching": "None",
            "write_accelerator": False,
            "lun_start": 0
        }
        
        assert result == expected

    def test_parse_standard_disk_config(self):
        """Test parsing of Standard SSD disk configuration"""
        result = self.generator.parse_disk_config("2 x E15", "backup")
        
        expected = {
            "name": "backup",
            "fullname": "",
            "count": 2,
            "disk_type": "StandardSSD_LRS",
            "size_gb": 256,
            "caching": "ReadOnly",
            "write_accelerator": False,
            "lun_start": 15
        }
        
        assert result == expected

    def test_parse_log_disk_with_write_accelerator(self):
        """Test that log disks get write accelerator enabled for Premium SSD"""
        result = self.generator.parse_disk_config("3 x P15", "log")
        
        assert result is not None
        assert result["name"] == "log"
        assert result["write_accelerator"] == True
        assert result["caching"] == "None"
        assert "fullname" not in result  # Log disks don't have fullname

    def test_parse_ultrassd_config(self):
        """Test parsing of UltraSSD configuration"""
        result = self.generator.parse_disk_config("UltraSSD", "log")
        
        expected = {
            "name": "log",
            "count": 1,
            "disk_type": "UltraSSD_LRS", 
            "size_gb": 128,
            "caching": "None",
            "write_accelerator": False,
            "disk_iops_read_write": 1800,
            "disk_mbps_read_write": 250,
            "lun_start": 9
        }
        
        assert result == expected

    def test_parse_premium_ssd_v2_config(self):
        """Test parsing of Premium SSD v2 configuration"""
        result = self.generator.parse_disk_config("PremiumV2 512GB 425MBps 3000IOPS", "data")
        
        expected = {
            "name": "data",
            "fullname": "",
            "count": 1,
            "disk_type": "PremiumV2_LRS",
            "size_gb": 512,
            "caching": "None",
            "write_accelerator": False,
            "disk_iops_read_write": 3000,
            "disk_mbps_read_write": 425,
            "lun_start": 0
        }
        
        assert result == expected

    def test_parse_premium_ssd_v2_log_config(self):
        """Test parsing of Premium SSD v2 log configuration"""
        result = self.generator.parse_disk_config("PremiumV2 256GB 275MBps 4000IOPS", "log")
        
        # Log disks should not have fullname
        assert result is not None
        assert result["name"] == "log"
        assert result["disk_type"] == "PremiumV2_LRS"
        assert result["size_gb"] == 256
        assert result["disk_iops_read_write"] == 4000
        assert result["disk_mbps_read_write"] == 275
        assert result["caching"] == "None"
        assert result["write_accelerator"] == False
        assert "fullname" not in result

    def test_parse_invalid_disk_config(self):
        """Test parsing of invalid disk configuration returns None"""
        result = self.generator.parse_disk_config("invalid config", "data")
        assert result is None

    def test_create_vm_configuration_basic(self):
        """Test creating a basic VM configuration"""
        result = self.generator.create_vm_configuration("M32ts", self.sample_config_data)
        
        # Check basic structure
        assert result["compute"]["vm_size"] == "Standard_M32ts"
        
        # Check that storage section exists and has correct structure
        assert "storage" in result
        storage = result["storage"]
        
        # Should have OS disk plus data/log/shared/sap/backup disks
        assert storage[0]["name"] == "os"

    def test_create_vm_configuration_with_swap(self):
        """Test creating VM configuration with swap size"""
        config_with_swap = self.sample_config_data.copy()
        config_with_swap["swap_size_gb"] = 32
        
        result = self.generator.create_vm_configuration("M32ls", config_with_swap)
        
        # Check basic structure
        assert result["compute"]["vm_size"] == "Standard_M32ls"
        assert result["compute"]["swap_size_gb"] == 32
        
        # Check that storage is included
        storage = result["storage"]
        
        # Count storage types - should have os, data, log, shared, sap, backup
        assert len(storage) == 6

    def test_create_vm_configuration_premium_ssd_v2(self):
        """Test creating VM configuration with Premium SSD v2"""
        premium_v2_config = {
            "memory_gb": 256,
            "data_config": "PremiumV2 307GB 425MBps 3000IOPS",
            "log_config": "PremiumV2 128GB 275MBps 3000IOPS",
            "shared_config": "PremiumV2 256GB 125MBps 3000IOPS",
            "sap_config": "1 x P6",
            "backup_config": "1 x P6"
        }
        
        result = self.generator.create_vm_configuration("E32ds_v4_v2", premium_v2_config)
        
        # Check basic structure
        assert result["compute"]["vm_size"] == "Standard_E32ds_v4_v2"
        
        # Check storage section
        storage = result["storage"]
        data_disk = next(disk for disk in storage if disk["name"] == "data")
        log_disk = next(disk for disk in storage if disk["name"] == "log")
        shared_disk = next(disk for disk in storage if disk["name"] == "shared")
        
        # Verify Premium SSD v2 configuration
        assert data_disk["disk_type"] == "PremiumV2_LRS"
        assert data_disk["size_gb"] == 307
        assert data_disk["disk_iops_read_write"] == 3000
        assert data_disk["disk_mbps_read_write"] == 425
        assert data_disk["caching"] == "None"
        assert data_disk["write_accelerator"] == False
        
        assert log_disk["disk_type"] == "PremiumV2_LRS"
        assert log_disk["disk_mbps_read_write"] == 275
        
        assert shared_disk["disk_type"] == "PremiumV2_LRS"
        assert shared_disk["disk_mbps_read_write"] == 125

    def test_create_vm_configuration_storage_count(self):
        """Test that VM configuration includes all expected storage types"""
        result = self.generator.create_vm_configuration("M32ts", self.sample_config_data)
        storage = result["storage"]
        
        # Extract storage names for easier checking
        storage_names = [disk["name"] for disk in storage]
        
        for name in ["os", "data", "log", "shared", "sap", "backup"]:
            assert name in storage_names

    def test_generate_all_configurations(self):
        """Test generating all configurations from mock data"""
        # Create a small subset of test data
        mock_config = {
            "M32ts": self.sample_config_data,
            "M64s": {
                "memory_gb": 384,
                "data_config": "4 x P15",
                "log_config": "3 x P10",
                "shared_config": "1 x P20", 
                "sap_config": "1 x P6",
                "backup_config": "1 x P10"
            }
        }
        
        with patch('simple_hana_generator.AZURE_HANA_CONFIGURATIONS', mock_config):
            result = self.generator.generate_all_configurations()
            
            assert len(result) == 2
            assert "M32ts" in result
            assert "M64s" in result

    def test_update_hana_sizes_file_dry_run(self):
        """Test dry run mode doesn't modify files"""
        # Create temporary file with existing content
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as tmp_file:
            json.dump(self.sample_existing_config, tmp_file)
            tmp_file_path = tmp_file.name
        
        try:
            # Mock the configuration generation to return a simple config
            with patch.object(self.generator, 'generate_all_configurations') as mock_gen:
                mock_gen.return_value = {"NewVM": {"compute": {"vm_size": "Standard_M32ts"}}}
                
                result_config = self.generator.update_hana_sizes_file(tmp_file_path, dry_run=True)
                
                # In dry run, should return the original config structure
                assert result_config is not None
                assert "db" in result_config
                
        finally:
            # Clean up
            os.unlink(tmp_file_path)

    def test_update_hana_sizes_file_missing_file(self):
        """Test handling of missing input file"""
        non_existent_path = "/tmp/non_existent_hana_sizes.json"
        
        # Mock configuration generation
        with patch.object(self.generator, 'generate_all_configurations') as mock_gen:
            mock_gen.return_value = {"M32ts": {"compute": {"vm_size": "Standard_M32ts"}}}
            
            # Should handle missing file gracefully
            result = self.generator.update_hana_sizes_file(non_existent_path, dry_run=True)
            
            # Should create new structure with generated configs
            assert result is not None
            assert "db" in result
            assert "M32ts" in result["db"]

    def test_update_hana_sizes_file_adds_new_config(self):
        """Test that new configurations are added to existing file"""
        # Create temporary file with existing content
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as tmp_file:
            json.dump(self.sample_existing_config, tmp_file)
            tmp_file_path = tmp_file.name
        
        try:
            with patch.object(self.generator, 'generate_all_configurations') as mock_gen:
                mock_gen.return_value = {"M32ts": {"compute": {"vm_size": "Standard_M32ts"}}}
                
                result_config = self.generator.update_hana_sizes_file(tmp_file_path, dry_run=True)
                
                # Should contain both original and new configs
                assert result_config is not None
                assert "M32ts" in result_config["db"]
                assert "Default" in result_config["db"]  # Original config preserved
        finally:
            # Clean up
            os.unlink(tmp_file_path)

    def test_caching_configuration_by_disk_type(self):
        """Test that caching is set correctly for different disk types"""
        # Test data disk (should be None)
        data_disk = self.generator.parse_disk_config("4 x P10", "data")
        assert data_disk is not None
        assert data_disk["caching"] == "None"
        
        # Test shared disk (should be ReadOnly)
        shared_disk = self.generator.parse_disk_config("1 x P15", "shared")
        assert shared_disk is not None
        assert shared_disk["caching"] == "ReadOnly"
        
        # Test log disk (should be None)
        log_disk = self.generator.parse_disk_config("3 x P10", "log")
        assert log_disk is not None
        assert log_disk["caching"] == "None"

    def test_lun_start_assignment(self):
        """Test that LUN start positions are assigned correctly"""
        data_disk = self.generator.parse_disk_config("4 x P10", "data")
        assert data_disk is not None
        assert data_disk["lun_start"] == 0
        
        log_disk = self.generator.parse_disk_config("3 x P10", "log")
        assert log_disk is not None
        assert log_disk["lun_start"] == 9
        
        shared_disk = self.generator.parse_disk_config("1 x P15", "shared")
        assert shared_disk is not None
        assert shared_disk["lun_start"] == 6


if __name__ == "__main__":
    pytest.main([__file__])
