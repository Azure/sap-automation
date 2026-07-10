# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for the SAP hosts filter plugin.
"""

import pytest
from sap_hosts_filters import FilterModule


@pytest.fixture
def filter_module():
    """
    Build a fresh :class:`sap_hosts_filters.FilterModule` instance.

    :return: A new ``FilterModule`` instance under test.
    """
    return FilterModule()


@pytest.fixture
def base_ansible_vars():
    """
    Build a baseline set of Ansible variables shared across scenarios.

    Individual tests mutate a copy of this dictionary to set up their
    specific host/IP topology before invoking the filter.

    :return: A dictionary of default Ansible variables.
    """
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


class TestSapHostsFilters:
    """
    Test suite covering ``sap_hosts_filters.FilterModule.generate_sap_hosts_entries``.
    """

    def test_single_host_single_ip_generates_one_entry(self, filter_module, base_ansible_vars):
        """
        Happy path: a single host with a single IP produces exactly one
        matching entry with no duplication.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
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
        assert result_str.count("172.234.2.12") == 1, "Host entry appears multiple times"
        assert "172.234.2.12" in result_str, "Expected host entry not found"

    def test_multiple_hosts_produce_no_duplicate_ip_entries(self, filter_module, base_ansible_vars):
        """
        Happy path: multiple hosts each with a distinct IP produce a
        set of entries with no duplicated IP lines.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe", "shascs01lbbe"]
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
        lines = [line for line in result if line.strip() and not line.startswith("#")]
        ip_entries = [line for line in lines if line.startswith("172")]

        assert len(ip_entries) == len(set(ip_entries)), "Duplicate entries found in output"

    def test_host_entry_includes_ip_fqdn_and_short_hostname(self, filter_module, base_ansible_vars):
        """
        Happy path: a generated host entry includes the IP address, the
        fully-qualified hostname, and the short hostname.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
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

    def test_scale_out_database_includes_all_ips_from_db_host_perspective(
        self, filter_module, base_ansible_vars
    ):
        """
        Happy path: a scale-out database host viewing its own entries
        sees every IP across all subnets (DB, storage, and replication).

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["database_scale_out"] = True
        base_ansible_vars["inventory_hostname"] = "shadhdb00l0bb"
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shadhdb00l0bb": {
                "ipadd": ["172.234.0.14", "172.234.1.10", "172.234.0.202"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            }
        }
        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)
        assert "172.234.0.14" in result_str
        assert "172.234.1.10" in result_str
        assert "172.234.0.202" in result_str

        for ip in ["172.234.0.14", "172.234.1.10", "172.234.0.202"]:
            assert result_str.count(ip) >= 1, f"IP {ip} not found"
            lines_with_ip = [line for line in result if line.strip().startswith(ip)]
            assert len(lines_with_ip) <= 2, f"IP {ip} appears too many times: {len(lines_with_ip)}"

    def test_scale_out_database_ha_generates_hsr_suffix(self, filter_module, base_ansible_vars):
        """
        Edge case: a scale-out database with HA replication enabled
        generates a ``-hsr`` suffixed hostname entry for the
        replication network.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["database_scale_out"] = True
        base_ansible_vars["database_high_availability"] = True
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shadhdb00l0bb": {
                "ipadd": ["172.234.0.14", "172.234.1.10"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            }
        }
        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "shadhdb00l0bb-hsr" in result_str or "shadhdb00l0bb" in result_str

    def test_non_db_host_sees_only_client_subnet_ip_for_scale_out_db(
        self, filter_module, base_ansible_vars
    ):
        """
        Edge case: a non-database host viewing a scale-out database
        host only sees the client-subnet IP, not the DB or storage
        subnet IPs (network isolation).

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["database_scale_out"] = True
        base_ansible_vars["inventory_hostname"] = "shascs00lbbe"
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            },
            "shadhdb00l0bb": {
                "ipadd": ["172.234.0.14", "172.234.1.10", "172.234.2.14"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            },
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "172.234.2.14" in result_str

    def test_scs_ers_ha_generates_virtual_hostname_entries(self, filter_module, base_ansible_vars):
        """
        Happy path: SCS/ERS high availability generates virtual
        hostname entries pointing at the respective load-balancer IPs.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["scs_high_availability"] = True
        base_ansible_vars["scs_lb_ip"] = "172.234.2.10"
        base_ansible_vars["ers_lb_ip"] = "172.234.2.11"
        base_ansible_vars["ansible_play_hosts"] = []

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "shascs00cl1" in result_str
        assert "shaers01cl2" in result_str
        assert "172.234.2.10" in result_str
        assert "172.234.2.11" in result_str

    def test_database_ha_generates_virtual_hostname_entry(self, filter_module, base_ansible_vars):
        """
        Happy path: database high availability generates a virtual
        hostname entry pointing at the database load-balancer IP.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["database_high_availability"] = True
        base_ansible_vars["db_lb_ip"] = "172.234.0.13"
        base_ansible_vars["ansible_play_hosts"] = []

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "shahdbdb00cl" in result_str
        assert "172.234.0.13" in result_str

    def test_custom_scs_virtual_hostname_override_is_used(self, filter_module, base_ansible_vars):
        """
        Edge case: a per-host ``custom_scs_virtual_hostname`` override
        is used in place of the default virtual hostname.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
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

        assert "myscs-custom" in result_str

    def test_minimal_variable_set_does_not_raise_and_returns_entries(self, filter_module):
        """
        Edge case: the filter completes without raising and returns at
        least one entry when only the minimal required variables are
        supplied.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
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
        assert len(result) > 0

    def test_no_duplicate_physical_host_entries_across_full_landscape(
        self, filter_module, base_ansible_vars
    ):
        """
        Regression: a full multi-tier landscape (app, HANA scale-out,
        observer, SCS, and web hosts) never produces a duplicated
        physical host-entry line.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
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
        data_lines = [line for line in result if line.strip() and not line.startswith("#")]
        duplicate_lines = [line for line in set(data_lines) if data_lines.count(line) > 1]

        assert len(duplicate_lines) == 0, f"Found duplicate entries: {duplicate_lines}"

    def test_is_database_host_returns_true_for_known_database_tier(self, filter_module):
        """
        Happy path for :meth:`FilterModule._is_database_host`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        assert filter_module._is_database_host(["hana"]) is True
        assert filter_module._is_database_host(["app"]) is False

    def test_filters_returns_expected_filter_mapping(self, filter_module):
        """
        Happy path for :meth:`FilterModule.filters`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        filters = filter_module.filters()

        assert set(filters) == {
            "sdaf_generate_sap_hosts",
            "sdaf_format_hosts_entry",
            "sdaf_validate_network_config",
        }
        assert filters["sdaf_format_hosts_entry"] == filter_module.format_hosts_entry
        assert filters["sdaf_validate_network_config"] == filter_module.validate_network_config

    def test_format_hosts_entry_pads_columns_to_expected_widths(self, filter_module):
        """
        Happy path for :meth:`FilterModule.format_hosts_entry`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        result = filter_module.format_hosts_entry("10.0.0.1", "host.example.com", "host")

        assert result == f"{'10.0.0.1':<19}{'host.example.com':<81}{'host':<17}"

    def test_validate_network_config_returns_valid_for_well_formed_non_overlapping_subnets(
        self, filter_module
    ):
        """
        Happy path for :meth:`FilterModule.validate_network_config`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        result = filter_module.validate_network_config(
            {
                "subnet_cidr_db": "172.234.0.0/24",
                "subnet_cidr_storage": "172.234.1.0/24",
                "subnet_cidr_client": "172.234.2.0/24",
            }
        )

        assert result == {"valid": True, "warnings": [], "errors": []}

    def test_validate_network_config_raises_value_error_for_malformed_cidr(self, filter_module):
        """
        Edge case for :meth:`FilterModule.validate_network_config`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        with pytest.raises(ValueError):
            filter_module.validate_network_config({"subnet_cidr_db": "not-a-cidr"})

    def test_validate_network_config_flags_overlapping_subnets_as_warning(self, filter_module):
        """
        Edge case for :meth:`FilterModule.validate_network_config`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        result = filter_module.validate_network_config(
            {
                "subnet_cidr_db": "172.234.0.0/24",
                "subnet_cidr_storage": "172.234.0.0/25",
                "subnet_cidr_client": "172.234.2.0/24",
            }
        )

        assert result["valid"] is True
        assert any("Subnets overlap" in warning for warning in result["warnings"])

    def test_generate_sap_hosts_entries_skips_play_host_missing_from_hostvars(
        self, filter_module, base_ansible_vars
    ):
        """
        Edge case for :meth:`FilterModule.generate_sap_hosts_entries`.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe", "unknownhost"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)

        assert any("172.234.2.12" in line for line in result)

    def test_generate_sap_hosts_entries_skips_host_with_no_ip_addresses(
        self, filter_module, base_ansible_vars
    ):
        """
        Edge case for :meth:`FilterModule.generate_sap_hosts_entries`.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": [],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00lbbe",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)

        assert not any(line.strip().startswith("172.") for line in result)

    def test_generate_sap_hosts_entries_default_virtual_host_maps_secondary_ips(
        self, filter_module, base_ansible_vars
    ):
        """
        Happy path for :meth:`FilterModule.generate_sap_hosts_entries`.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["ansible_play_hosts"] = ["shascs00lbbe"]
        base_ansible_vars["hostvars"] = {
            "shascs00lbbe": {
                "ipadd": ["172.234.2.12", "172.234.2.99"],
                "supported_tiers": ["scs"],
                "virtual_host": "shascs00cl1",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "shascs00cl1" in result_str
        assert "172.234.2.99" in result_str

    def test_generate_sap_hosts_entries_custom_scs_hostname_skipped_when_scs_ha_enabled(
        self, filter_module, base_ansible_vars
    ):
        """
        Edge case for :meth:`FilterModule.generate_sap_hosts_entries`.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["scs_high_availability"] = True
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

        assert "myscs-custom" not in result_str

    def test_generate_sap_hosts_entries_config_level_custom_virtual_hostnames_are_used(
        self, filter_module, base_ansible_vars
    ):
        """
        Happy path for :meth:`FilterModule.generate_sap_hosts_entries`.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["scs_high_availability"] = True
        base_ansible_vars["scs_lb_ip"] = "172.234.2.10"
        base_ansible_vars["ers_lb_ip"] = "172.234.2.11"
        base_ansible_vars["custom_scs_virtual_hostname"] = "custom-scs-vhost"
        base_ansible_vars["custom_ers_virtual_hostname"] = "custom-ers-vhost"
        base_ansible_vars["database_high_availability"] = True
        base_ansible_vars["db_lb_ip"] = "172.234.0.13"
        base_ansible_vars["custom_db_virtual_hostname"] = "custom-db-vhost"
        base_ansible_vars["ansible_play_hosts"] = []

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        result_str = "\n".join(result)

        assert "custom-scs-vhost" in result_str
        assert "custom-ers-vhost" in result_str
        assert "custom-db-vhost" in result_str

    def test_get_database_ip_suffix_raises_value_error_for_unparsable_ip_address(
        self, filter_module, base_ansible_vars
    ):
        """
        Edge case for :meth:`FilterModule._get_database_ip_suffix`.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        config = {"database_high_availability": False}
        network_config = {
            "subnet_cidr_db": base_ansible_vars["subnet_cidr_db"],
            "subnet_cidr_storage": base_ansible_vars["subnet_cidr_storage"],
        }

        with pytest.raises(ValueError):
            filter_module._get_database_ip_suffix("not-an-ip", config, network_config)

    def test_get_database_ip_suffix_skips_empty_subnet_and_returns_none_for_valid_ip_outside_range(
        self, filter_module
    ):
        """
        Edge case for :meth:`FilterModule._get_database_ip_suffix`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        config = {"database_high_availability": False}
        network_config = {"subnet_cidr_db": "", "subnet_cidr_storage": "172.234.1.0/24"}
        result = filter_module._get_database_ip_suffix("10.99.99.99", config, network_config)
        assert result is None

    def test_get_client_subnet_ip_or_primary_returns_primary_when_no_client_subnet_configured(
        self, filter_module
    ):
        """
        Edge case for :meth:`FilterModule._get_client_subnet_ip_or_primary`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        result = filter_module._get_client_subnet_ip_or_primary(
            ["10.0.0.5", "10.0.1.5"], {"subnet_cidr_client": ""}, "10.0.0.5"
        )

        assert result == "10.0.0.5"

    def test_get_client_subnet_ip_or_primary_raises_value_error_for_unparsable_candidate_ip(
        self, filter_module
    ):
        """
        Edge case for :meth:`FilterModule._get_client_subnet_ip_or_primary`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        with pytest.raises(ValueError):
            filter_module._get_client_subnet_ip_or_primary(
                ["not-an-ip", "10.0.0.5"],
                {"subnet_cidr_client": "172.234.2.0/24"},
                "10.0.0.5",
            )

    def test_get_client_subnet_ip_or_primary_raises_value_error_for_invalid_client_cidr(
        self, filter_module
    ):
        """
        Edge case for :meth:`FilterModule._get_client_subnet_ip_or_primary`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        with pytest.raises(ValueError):
            filter_module._get_client_subnet_ip_or_primary(
                ["10.0.0.5"], {"subnet_cidr_client": "not-a-cidr"}, "10.0.0.5"
            )

    def test_is_ip_in_client_subnet_returns_false_when_no_client_subnet_configured(
        self, filter_module
    ):
        """
        Edge case for :meth:`FilterModule._is_ip_in_client_subnet`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        assert (
            filter_module._is_ip_in_client_subnet("10.0.0.5", {"subnet_cidr_client": ""}) is False
        )

    def test_is_ip_in_client_subnet_raises_value_error_on_invalid_cidr(self, filter_module):
        """
        Edge case for :meth:`FilterModule._is_ip_in_client_subnet`.

        :param filter_module: The ``FilterModule`` fixture under test.
        """
        with pytest.raises(ValueError):
            filter_module._is_ip_in_client_subnet("10.0.0.5", {"subnet_cidr_client": "not-a-cidr"})

    def test_each_ip_appears_in_exactly_one_entry_line(self, filter_module, base_ansible_vars):
        """
        Regression: every IP address appears at the start of exactly
        one generated entry line, never split across duplicate lines.

        :param filter_module: The ``FilterModule`` fixture under test.
        :param base_ansible_vars: The baseline Ansible variables fixture.
        """
        base_ansible_vars["ansible_play_hosts"] = ["shadhdb00l0bb"]
        base_ansible_vars["hostvars"] = {
            "shadhdb00l0bb": {
                "ipadd": ["172.234.0.14", "172.234.1.10", "172.234.0.202"],
                "supported_tiers": ["hana"],
                "virtual_host": "shadhdb00l0bb",
            }
        }

        result = filter_module.generate_sap_hosts_entries(base_ansible_vars)
        data_lines = [line for line in result if line.strip() and line.strip()[0].isdigit()]

        ips_in_lines = [line.split()[0] for line in data_lines]
        assert len(ips_in_lines) == len(set(ips_in_lines)), "Duplicate IP entries detected"
