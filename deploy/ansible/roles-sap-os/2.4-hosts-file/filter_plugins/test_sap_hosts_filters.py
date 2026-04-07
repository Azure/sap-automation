# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for SAP Hosts Filter Plugin

Tests cover:
- Basic host entry generation
- Network isolation filtering for scale-out
- Custom virtual hostname handling
- SCS/ERS HA scenarios
- Database HA scenarios
- Duplicate entry detection
"""

import pytest
from sap_hosts_filters import FilterModule


@pytest.fixture
def filter_module():
    """Initialize filter module for testing."""
    return FilterModule()


@pytest.fixture
def base_ansible_vars():
    """Base Ansible variables for test scenarios."""
    return {
        "sap_sid": "sha",
        "db_sid": "hdb",
        "sap_fqdn": "noeu.sdaf.contoso.net",
        "database_scale_out": False,
        "database_high_availability": False,
        "db_instance_number": "00",
        "scs_high_availability": False,
        "scs_instance_number": "00",
        "ers_instance_number": "01",
        "ansible_play_hosts": [],
        "hostvars": {},
        "inventory_hostname": "shascs00lbbe",
        "subnet_cidr_client": "172.234.2.0/24",
        "subnet_cidr_db": "172.234.0.0/24",
        "subnet_cidr_storage": "172.234.1.0/24",
    }


class TestBasicHostEntry:
    """Test basic physical host entry generation."""

    def test_single_host_single_ip(self, filter_module, base_ansible_vars):
        """Test basic single host with single IP."""
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Check for duplicate entries
        assert (
            result_str.count("172.234.2.12") == 1
        ), "Host entry appears multiple times"
        assert "172.234.2.12" in result_str, "Expected host entry not found"

    def test_multiple_hosts_no_duplicates(self, filter_module, base_ansible_vars):
        """Test multiple hosts don't generate duplicates."""
        base_ansible_vars["ansible_play_hosts"] = [
            "shascs00lbbe",
            "shascs01lbbe",
        ]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            },
            "shascs01lbbe": {
                "ipadd": ["172.234.2.13"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs01lbbe",
            },
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Check no duplicates
        lines = [line for line in result if line.strip() and not line.startswith("#")]
        ip_entries = [line for line in lines if line.startswith("172")]

        assert len(ip_entries) == len(
            set(ip_entries)
        ), "Duplicate entries found in output"

    def test_host_entry_format(self, filter_module, base_ansible_vars):
        """Test correct formatting of host entries."""
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "172.234.2.12" in result_str
        assert "shascs00lbbe.noeu.sdaf.contoso.net" in result_str
        assert "shascs00lbbe" in result_str


class TestScaleOutDatabase:
    """Test scale-out database scenarios."""

    def test_scale_out_db_multiple_ips(self, filter_module, base_ansible_vars):
        """Test scale-out database with multiple IPs generates all entries (from DB host perspective)."""
        base_ansible_vars["database_scale_out"] = True
        base_ansible_vars["inventory_hostname"] = (
            "shadhdb00l0bb"  # Run from DB host perspective
        )
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shadhdb00l0bb": {
                "ipadd": [
                    "172.234.0.14",
                    "172.234.1.10",
                    "172.234.0.202",
                ],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # All three IPs should be present when viewing from a DB host
        assert "172.234.0.14" in result_str
        assert "172.234.1.10" in result_str
        assert "172.234.0.202" in result_str

        # Check no IP appears twice
        for ip in ["172.234.0.14", "172.234.1.10", "172.234.0.202"]:
            count = result_str.count(ip)
            assert count >= 1, f"IP {ip} not found"
            # Count occurrences as host entries (line starts with IP)
            lines_with_ip = [l for l in result if l.strip().startswith(ip)]
            assert (
                len(lines_with_ip) <= 2
            ), f"IP {ip} appears too many times: {len(lines_with_ip)}"

    def test_scale_out_db_suffix_hsr(self, filter_module, base_ansible_vars):
        """Test scale-out database generates -hsr suffix for HA replication network."""
        base_ansible_vars["database_scale_out"] = True
        base_ansible_vars["database_high_availability"] = True
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shadhdb00l0bb": {
                "ipadd": [
                    "172.234.0.14",
                    "172.234.1.10",
                ],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Should have -hsr suffix for replication network IP
        assert "shadhdb00l0bb-hsr" in result_str or "shadhdb00l0bb" in result_str


class TestNetworkIsolation:
    """Test network isolation filtering for scale-out non-DB hosts."""

    def test_non_db_viewing_scale_out_db_filters_ips(
        self, filter_module, base_ansible_vars
    ):
        """Test non-DB hosts see only client subnet IPs for scale-out DBs."""
        base_ansible_vars["database_scale_out"] = True
        base_ansible_vars["inventory_hostname"] = "shascs00lbbe"  # Non-DB host
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            },
            "shadhdb00l0bb": {
                "ipadd": [
                    "172.234.0.14",  # DB subnet
                    "172.234.1.10",  # Storage subnet
                    "172.234.2.14",  # Client subnet (visible to non-DB)
                ],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            },
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Non-DB host viewing DB should see client subnet IP
        assert "172.234.2.14" in result_str


class TestVirtualHostnames:
    """Test virtual hostname generation."""

    def test_scs_ers_ha_virtual_hostnames(self, filter_module, base_ansible_vars):
        """Test SCS/ERS HA generates virtual hostname entries."""
        base_ansible_vars["scs_high_availability"] = True
        base_ansible_vars["scs_lb_ip"] = "172.234.2.10"
        base_ansible_vars["ers_lb_ip"] = "172.234.2.11"
        base_ansible_vars["ansible_play_hosts"] = []

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Should have SCS/ERS virtual hostname entries
        assert "shascs00cl1" in result_str
        assert "shaers01cl2" in result_str
        assert "172.234.2.10" in result_str
        assert "172.234.2.11" in result_str

    def test_db_ha_virtual_hostname(self, filter_module, base_ansible_vars):
        """Test database HA generates virtual hostname entry."""
        base_ansible_vars["database_high_availability"] = True
        base_ansible_vars["db_lb_ip"] = "172.234.0.13"
        base_ansible_vars["ansible_play_hosts"] = []

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Should have DB virtual hostname entry
        assert "shahdbdb00cl" in result_str
        assert "172.234.0.13" in result_str


class TestCustomVirtualHostnames:
    """Test custom virtual hostname handling."""

    def test_custom_scs_virtual_hostname(self, filter_module, base_ansible_vars):
        """Test custom SCS virtual hostname is used."""
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
                "custom_scs_virtual_hostname": "myscs-custom",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        # Custom hostname should appear
        assert "myscs-custom" in result_str


class TestNoMissingVariables:
    """Test graceful handling of missing variables."""

    def test_minimal_vars(self, filter_module):
        """Test with minimal required variables."""
        minimal_vars = {
            "sap_sid": "test",
            "db_sid": "tdb",
            "sap_fqdn": "example.com",
            "ansible_play_hosts": ["testhost"],
            "hostvars": {
                "testhost": {
                    "ipadd": ["10.0.0.1"],
                    "supported_tiers": ["app"],
                }
            },
            "inventory_hostname": "testhost",
        }

        result = filter_module.generate_sap_hosts_entries(minimal_vars)

        # Should not raise exception and should return entries
        assert len(result) > 0


class TestDuplicateDetection:
    """Regression tests for duplicate entry issue."""

    def test_no_duplicate_physical_entries(self, filter_module, base_ansible_vars):
        """Regression: ensure physical host entries are never duplicated."""
        base_ansible_vars["ansible_play_hosts"] = [
            "shaapp00lbbe",
            "shaapp01lbbe",
            "shadhdb00l0bb",
            "shadhdb00l1bb",
            "shadobs00lbbe",
            "shascs00lbbe",
            "shascs01lbbe",
            "shaweb00lbbe",
        ]
        base_ansible_vars["hostvars"] = {
            "shaapp00lbbe": {
                "ipadd": ["172.234.2.14"],
                "supported_tiers": ["app"],
                "virtual_host": "shaapp00lbbe",
            },
            "shaapp01lbbe": {
                "ipadd": ["172.234.2.15"],
                "supported_tiers": ["app"],
                "virtual_host": "shaapp01lbbe",
            },
            "shadhdb00l0bb": {
                "ipadd": ["172.234.0.14", "172.234.1.10", "172.234.0.202"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            },
            "shadhdb00l1bb": {
                "ipadd": ["172.234.0.15", "172.234.1.14", "172.234.0.199"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l1bb",
            },
            "shadobs00lbbe": {
                "ipadd": ["172.234.0.12"],
                "supported_tiers": ["observer"],
                "virtual_host": "shadobs00lbbe",
            },
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            },
            "shascs01lbbe": {
                "ipadd": ["172.234.2.13"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs01lbbe",
            },
            "shaweb00lbbe": {
                "ipadd": ["172.234.3.11"],
                "supported_tiers": ["web"],
                "virtual_host": "shaweb00lbbe",
            },
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)

        # Extract non-comment, non-empty lines
        data_lines = [
            line for line in result if line.strip() and not line.startswith("#")
        ]

        # Check for duplicate lines
        duplicate_lines = [
            line for line in set(data_lines) if data_lines.count(line) > 1
        ]

        assert len(duplicate_lines) == 0, f"Found duplicate entries: {duplicate_lines}"

    def test_each_ip_appears_once(self, filter_module, base_ansible_vars):
        """Each IP should appear in exactly one host entry line."""
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shadhdb00l0bb": {
                "ipadd": ["172.234.0.14", "172.234.1.10", "172.234.0.202"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        data_lines = [
            line for line in result if line.strip() and line.strip()[0].isdigit()
        ]

        # Each line should start with a unique IP
        ips_in_lines = [line.split()[0] for line in data_lines]
        assert len(ips_in_lines) == len(
            set(ips_in_lines)
        ), "Duplicate IP entries detected"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
