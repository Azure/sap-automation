# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
SAP Hosts Filter Plugin for Ansible

This Ansible filter plugin generates /etc/hosts entries for SAP systems
deployed on Azure using the SDAF (SAP Deployment Automation Framework)
pattern. It replaces the existing Jinja template with a Python
implementation that handles all SAP scenarios including scale-up,
scale-out, HA, network isolation, and custom virtual hostname
configurations.

Author: SDAF Core Dev Team
Context: Azure SDAF SAP deployments
Integration: Called from within 2.4-hosts-file role
"""

import ipaddress
from typing import Dict, List, Optional, Any


DB_TIERS = {"hana", "oracle", "oracle-asm", "db2", "sybase"}
SCALE_OUT_DB_TIERS = {"hana"}


class FilterModule:
    """
    Ansible filter plugin for SAP hosts file generation in Azure SDAF
    deployments.
    """

    def filters(self):
        return {
            "sdaf_generate_sap_hosts": self.generate_sap_hosts_entries,
            "sdaf_format_hosts_entry": self.format_hosts_entry,
            "sdaf_validate_network_config": self.validate_network_config,
        }

    def _is_database_host(self, supported_tiers: List[str]) -> bool:
        """Return True when a host contains any DB tier used by the hosts template."""
        return any(tier in DB_TIERS for tier in supported_tiers)

    def _is_scale_out_db_host(self, supported_tiers: List[str]) -> bool:
        """Return True when a host is in a DB tier that supports scale-out behavior."""
        return any(tier in SCALE_OUT_DB_TIERS for tier in supported_tiers)

    def generate_sap_hosts_entries(self, ansible_vars: Dict[str, Any]) -> List[str]:
        """
        Main filter function to generate complete SAP hosts file content.

        :param ansible_vars: Dictionary containing all Ansible variables, including
            ``ansible_play_hosts``, ``hostvars`` (with ``ipadd`` arrays),
            ``inventory_hostname``, ``sap_sid``, ``sap_fqdn``, database
            configuration (scale-out/HA/load balancer IPs), SCS/ERS
            configuration (HA/load balancer IPs/instance numbers), network
            configuration (subnet CIDRs including ``subnet_cidr_client``), and
            custom virtual hostname overrides.
        :type ansible_vars: Dict[str, Any]
        :returns: Formatted hosts file entries ready to be written to
            ``/etc/hosts``.
        :rtype: List[str]
        """
        # Extract and normalize configuration
        config = self._extract_sap_configuration(ansible_vars)
        network_config = self._extract_network_configuration(ansible_vars)

        # Determine if current host is a DB VM for filtering logic
        current_hostname = ansible_vars.get("inventory_hostname", "")
        current_host_vars = ansible_vars.get("hostvars", {}).get(current_hostname, {})
        current_host_tiers = current_host_vars.get("supported_tiers", [])
        is_current_host_db_vm = self._is_scale_out_db_host(current_host_tiers)

        # Generate all hosts file sections
        entries = []

        # Add main hosts section header
        entries.extend(self._generate_main_section_header(config, ansible_vars))
        entries.append("")

        # Generate physical host entries with network isolation filtering
        physical_entries = self._generate_physical_host_entries(
            ansible_vars, config, network_config, is_current_host_db_vm
        )
        entries.extend(physical_entries)

        # Add main section footer
        entries.extend(self._generate_main_section_footer(config))

        # Generate virtual hostname sections (always visible to all hosts)
        virtual_sections = self._generate_virtual_hostname_sections(
            ansible_vars, config
        )
        entries.extend(virtual_sections)

        return entries

    def _extract_sap_configuration(
        self, ansible_vars: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Extract and normalize SAP configuration from Ansible variables."""
        return {
            "sap_sid": ansible_vars.get("sap_sid", "").upper(),
            "sap_fqdn": ansible_vars.get("sap_fqdn", ""),
            "db_sid": ansible_vars.get("db_sid", "").upper(),
            # Database configuration with backwards compatibility
            "database_scale_out": ansible_vars.get("database_scale_out", False),
            "database_high_availability": ansible_vars.get(
                "database_high_availability",
                ansible_vars.get("db_high_availability", False),
            ),
            "db_instance_number": ansible_vars.get("db_instance_number", "00"),
            "db_lb_ip": ansible_vars.get(
                "database_loadbalancer_ip", ansible_vars.get("db_lb_ip")
            ),
            # SCS/ERS configuration
            "scs_high_availability": ansible_vars.get("scs_high_availability", False),
            "scs_instance_number": ansible_vars.get("scs_instance_number", "00"),
            "ers_instance_number": ansible_vars.get("ers_instance_number", "01"),
            "scs_lb_ip": ansible_vars.get("scs_lb_ip"),
            "ers_lb_ip": ansible_vars.get("ers_lb_ip"),
            # Custom virtual hostname overrides
            "custom_scs_virtual_hostname": ansible_vars.get(
                "custom_scs_virtual_hostname"
            ),
            "custom_ers_virtual_hostname": ansible_vars.get(
                "custom_ers_virtual_hostname"
            ),
            "custom_db_virtual_hostname": ansible_vars.get(
                "custom_db_virtual_hostname"
            ),
            "custom_pas_virtual_hostname": ansible_vars.get(
                "custom_pas_virtual_hostname"
            ),
            "custom_app_virtual_hostname": ansible_vars.get(
                "custom_app_virtual_hostname"
            ),
            "custom_web_virtual_hostname": ansible_vars.get(
                "custom_web_virtual_hostname"
            ),
        }

    def _extract_network_configuration(
        self, ansible_vars: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Extract network configuration from Ansible variables."""
        subnet_db = ansible_vars.get("subnet_cidr_db", "")
        subnet_storage = ansible_vars.get("subnet_cidr_storage", "")
        subnet_client = ansible_vars.get("subnet_cidr_client", "")

        return {
            "subnet_cidr_db": (
                subnet_db if subnet_db and len(subnet_db.strip()) > 0 else None
            ),
            "subnet_cidr_storage": (
                subnet_storage
                if subnet_storage and len(subnet_storage.strip()) > 0
                else None
            ),
            "subnet_cidr_client": (
                subnet_client
                if subnet_client and len(subnet_client.strip()) > 0
                else None
            ),
        }

    def _generate_main_section_header(
        self, config: Dict[str, Any], ansible_vars: Dict[str, Any]
    ) -> List[str]:
        """Generate the main section header with configuration summary."""
        ansible_play_hosts = ansible_vars.get("ansible_play_hosts", [])
        network_config = self._extract_network_configuration(ansible_vars)

        # Determine if network isolation is active
        current_hostname = ansible_vars.get("inventory_hostname", "")
        current_host_vars = ansible_vars.get("hostvars", {}).get(current_hostname, {})
        current_host_tiers = current_host_vars.get("supported_tiers", [])
        is_current_host_db_vm = self._is_scale_out_db_host(current_host_tiers)

        network_isolation_active = (
            config["database_scale_out"]
            and not is_current_host_db_vm
            and network_config["subnet_cidr_client"] is not None
        )

        header = [
            f"# BEGIN ANSIBLE MANAGED BLOCK - {config['sap_sid']}",
            f"# SID: {config['sap_sid']}",
            f"# {len(ansible_play_hosts)} Hosts",
            f"# Scale out: {config['database_scale_out']}",
            f"# High availability: {config['database_high_availability']}",
            f"# Subnet DB valid: {network_config['subnet_cidr_db'] is not None}",
            f"# Subnet Storage valid: {network_config['subnet_cidr_storage'] is not None}",
            f"# Subnet Client valid: {network_config['subnet_cidr_client'] is not None}",
        ]

        if network_isolation_active:
            header.append(
                f"# Network isolation: Active (Non-DB host view - showing client subnet IPs only)"
            )
        elif config["database_scale_out"] and is_current_host_db_vm:
            header.append(
                f"# Network isolation: Disabled (DB host view - showing all IPs)"
            )

        return header

    def _generate_main_section_footer(self, config: Dict[str, Any]) -> List[str]:
        """Generate the main section footer."""
        return [f"# END ANSIBLE MANAGED BLOCK - {config['sap_sid']}"]

    def _generate_physical_host_entries(
        self,
        ansible_vars: Dict[str, Any],
        config: Dict[str, Any],
        network_config: Dict[str, Any],
        is_current_host_db_vm: bool,
    ) -> List[str]:
        """Generate physical host entries with network isolation filtering for scale-out."""
        entries = []
        ansible_play_hosts = ansible_vars.get("ansible_play_hosts", [])
        hostvars = ansible_vars.get("hostvars", {})

        for hostname in sorted(ansible_play_hosts):
            if hostname not in hostvars:
                continue

            host_vars = hostvars[hostname]
            host_entries = self._generate_single_host_entries(
                hostname, host_vars, config, network_config, is_current_host_db_vm
            )
            entries.extend(host_entries)

        return entries

    def _generate_single_host_entries(
        self,
        hostname: str,
        host_vars: Dict[str, Any],
        config: Dict[str, Any],
        network_config: Dict[str, Any],
        is_current_host_db_vm: bool,
    ) -> List[str]:
        """Generate all entries for a single host with network isolation filtering."""
        entries = []
        ip_addresses = host_vars.get("ipadd", [])

        if not ip_addresses:
            return entries

        primary_ip = ip_addresses[0]
        secondary_ips = ip_addresses[1:] if len(ip_addresses) > 1 else []

        # Get host tier information
        supported_tiers = host_vars.get("supported_tiers", [])
        is_target_host_db_vm = self._is_scale_out_db_host(supported_tiers)
        default_virtual_host = host_vars.get("virtual_host")

        # Determine if we need to apply network isolation filtering
        apply_filtering = (
            not is_current_host_db_vm
            and is_target_host_db_vm
            and config["database_scale_out"]
        )

        if apply_filtering:
            # For non-DB hosts viewing DB hosts: filter IPs to client subnet only
            filtered_primary_ip = self._get_client_subnet_ip_or_primary(
                ip_addresses, network_config, primary_ip
            )

            # Primary hostname entry (using client subnet IP or primary IP)
            if filtered_primary_ip:
                entries.append(
                    self._format_hosts_entry(
                        filtered_primary_ip,
                        f"{hostname}.{config['sap_fqdn']}",
                        hostname,
                    )
                )

            # Custom virtual hostname entries for non-DB targets
            custom_virtual_entries = self._generate_custom_virtual_hostname_entries(
                hostname, host_vars, config, filtered_primary_ip, supported_tiers
            )
            entries.extend(custom_virtual_entries)

            # Scale-out entries: only show client subnet IPs
            for secondary_ip in secondary_ips:
                if self._is_ip_in_client_subnet(secondary_ip, network_config):
                    scale_out_entries = self._generate_database_scale_out_entries(
                        hostname, secondary_ip, config, network_config
                    )
                    entries.extend(scale_out_entries)

        else:
            # Normal processing: show all IPs (DB VMs or non-DB target hosts)

            # Primary hostname entry
            entries.append(
                self._format_hosts_entry(
                    primary_ip, f"{hostname}.{config['sap_fqdn']}", hostname
                )
            )

            # Custom virtual hostname entries (non-HA scenarios)
            custom_virtual_entries = self._generate_custom_virtual_hostname_entries(
                hostname, host_vars, config, primary_ip, supported_tiers
            )
            entries.extend(custom_virtual_entries)

            # Secondary IP entries for scale-out database scenarios
            if config["database_scale_out"] and is_target_host_db_vm:
                for secondary_ip in secondary_ips:
                    scale_out_entries = self._generate_database_scale_out_entries(
                        hostname, secondary_ip, config, network_config
                    )
                    entries.extend(scale_out_entries)

            # Default virtual host entry: map to primary IP / VIP only, if defined
            if default_virtual_host:
                entries.append(
                    self._format_hosts_entry(
                        primary_ip,
                        f"{default_virtual_host}.{config['sap_fqdn']}",
                        default_virtual_host,
                    )
                )
        return entries

    def _generate_custom_virtual_hostname_entries(
        self,
        hostname: str,
        host_vars: Dict[str, Any],
        config: Dict[str, Any],
        primary_ip: str,
        supported_tiers: List[str],
    ) -> List[str]:
        """Generate custom virtual hostname entries with hosts.j2-compatible tier rules."""
        entries = []
        added_hostnames = set()
        default_virtual_host = host_vars.get("virtual_host")

        # Check each tier for custom virtual hostnames.
        # Values are resolved per-target-host from host_vars to avoid cross-host leakage.
        tier_mapping = {
            "scs": "custom_scs_virtual_hostname",
            "ers": "custom_ers_virtual_hostname",
            "pas": "custom_pas_virtual_hostname",
            "app": "custom_app_virtual_hostname",
            "web": "custom_web_virtual_hostname",
        }

        for tier in supported_tiers:
            if tier in DB_TIERS:
                custom_key = "custom_db_virtual_hostname"
            elif tier in tier_mapping:
                custom_key = tier_mapping[tier]
            else:
                continue

            # Match hosts.j2 behavior: do not add SCS/ERS custom aliases when SCS HA is enabled.
            if tier in {"scs", "ers"} and config["scs_high_availability"]:
                continue

            custom_hostname = host_vars.get(custom_key)

            if (
                custom_hostname
                and custom_hostname != default_virtual_host
                and custom_hostname not in added_hostnames
            ):
                entries.append(
                    self._format_hosts_entry(
                        primary_ip,
                        f"{custom_hostname}.{config['sap_fqdn']}",
                        custom_hostname,
                    )
                )
                added_hostnames.add(custom_hostname)

        return entries

    def _generate_database_scale_out_entries(
        self,
        hostname: str,
        ip_address: str,
        config: Dict[str, Any],
        network_config: Dict[str, Any],
    ) -> List[str]:
        """Generate database scale-out entries with proper suffixes."""
        entries = []
        suffix = self._get_database_ip_suffix(ip_address, config, network_config)

        if suffix:
            hostname_with_suffix = f"{hostname}{suffix}"
            entries.append(
                self._format_hosts_entry(
                    ip_address,
                    f"{hostname_with_suffix}.{config['sap_fqdn']}",
                    hostname_with_suffix,
                )
            )

        return entries

    def _get_database_ip_suffix(
        self, ip_address: str, config: Dict[str, Any], network_config: Dict[str, Any]
    ) -> Optional[str]:
        """Determine suffix for database scale-out IP addresses."""
        try:
            ip_obj = ipaddress.ip_address(ip_address)

            # Check database subnet (use -hsr for HA, -hana for non-HA)
            if network_config["subnet_cidr_db"]:
                try:
                    db_network = ipaddress.ip_network(
                        network_config["subnet_cidr_db"], strict=False
                    )
                    if ip_obj in db_network:
                        return (
                            "-hsr" if config["database_high_availability"] else "-hana"
                        )
                except (ipaddress.AddressValueError, ipaddress.NetmaskValueError):
                    pass

            # Check storage subnet (use -inter for HA, -storage for non-HA)
            if network_config["subnet_cidr_storage"]:
                try:
                    storage_network = ipaddress.ip_network(
                        network_config["subnet_cidr_storage"], strict=False
                    )
                    if ip_obj in storage_network:
                        return (
                            "-inter"
                            if config["database_high_availability"]
                            else "-storage"
                        )
                except (ipaddress.AddressValueError, ipaddress.NetmaskValueError):
                    pass

        except ipaddress.AddressValueError:
            pass

        return None

    def _get_client_subnet_ip_or_primary(
        self, ip_addresses: List[str], network_config: Dict[str, Any], primary_ip: str
    ) -> str:
        """
        Find IP address in client subnet, or return primary IP if none found.

        Args:
            ip_addresses: List of all IP addresses for the host
            network_config: Network configuration including subnet_cidr_client
            primary_ip: Primary (first) IP address as fallback

        Returns:
            IP address in client subnet, or primary IP if none found
        """
        if not network_config["subnet_cidr_client"]:
            return primary_ip

        try:
            client_network = ipaddress.ip_network(
                network_config["subnet_cidr_client"], strict=False
            )

            # Find first IP that belongs to client subnet
            for ip_addr in ip_addresses:
                try:
                    if ipaddress.ip_address(ip_addr) in client_network:
                        return ip_addr
                except ipaddress.AddressValueError:
                    continue

        except (ipaddress.AddressValueError, ipaddress.NetmaskValueError):
            pass

        # Fallback to primary IP if no client subnet IP found
        return primary_ip

    def _is_ip_in_client_subnet(
        self, ip_address: str, network_config: Dict[str, Any]
    ) -> bool:
        """Check if IP address belongs to client subnet."""
        if not network_config["subnet_cidr_client"]:
            return False

        try:
            client_network = ipaddress.ip_network(
                network_config["subnet_cidr_client"], strict=False
            )
            return ipaddress.ip_address(ip_address) in client_network
        except (ipaddress.AddressValueError, ipaddress.NetmaskValueError):
            return False

    def _generate_virtual_hostname_sections(
        self, ansible_vars: Dict[str, Any], config: Dict[str, Any]
    ) -> List[str]:
        """Generate separate sections for virtual hostnames with load balancer IPs."""
        sections = []

        # Generate SCS/ERS section
        scs_ers_section = self._generate_scs_ers_section(config)
        if scs_ers_section:
            sections.append("")  # Blank line before section
            sections.extend(scs_ers_section)

        # Generate Database section
        db_section = self._generate_database_section(config)
        if db_section:
            sections.append("")  # Blank line before section
            sections.extend(db_section)

        return sections

    def _generate_scs_ers_section(self, config: Dict[str, Any]) -> List[str]:
        """Generate SCS/ERS virtual hostname section."""
        if not config["scs_high_availability"]:
            return []

        entries = []
        scs_virtual_hostname = self._get_scs_virtual_hostname(config)
        ers_virtual_hostname = self._get_ers_virtual_hostname(config)

        # Section header
        entries.append(f"# BEGIN ASCS/ERS Entries {scs_virtual_hostname}")

        # SCS virtual hostname with load balancer IP
        if config["scs_lb_ip"]:
            entries.append(
                self._format_hosts_entry(
                    config["scs_lb_ip"],
                    f"{scs_virtual_hostname}.{config['sap_fqdn']}",
                    scs_virtual_hostname,
                )
            )

        # ERS virtual hostname with load balancer IP
        if config["ers_lb_ip"]:
            entries.append(
                self._format_hosts_entry(
                    config["ers_lb_ip"],
                    f"{ers_virtual_hostname}.{config['sap_fqdn']}",
                    ers_virtual_hostname,
                )
            )

        # Section footer
        entries.append(f"# END ASCS/ERS Entries {scs_virtual_hostname}")

        return entries

    def _generate_database_section(self, config: Dict[str, Any]) -> List[str]:
        """Generate database virtual hostname section."""
        if not config["database_high_availability"] or not config["db_lb_ip"]:
            return []

        entries = []
        db_virtual_hostname = self._get_db_virtual_hostname(config)

        # Section header
        entries.append(f"# BEGIN DB Entries {db_virtual_hostname}")

        # Database virtual hostname with load balancer IP
        entries.append(
            self._format_hosts_entry(
                config["db_lb_ip"],
                f"{db_virtual_hostname}.{config['sap_fqdn']}",
                db_virtual_hostname,
            )
        )

        # Section footer
        entries.append(f"# END DB Entries {db_virtual_hostname}")

        return entries

    def _get_scs_virtual_hostname(self, config: Dict[str, Any]) -> str:
        """Generate SCS virtual hostname according to SDAF pattern."""
        if config["custom_scs_virtual_hostname"]:
            return config["custom_scs_virtual_hostname"]

        return f"{config['sap_sid'].lower()}scs{config['scs_instance_number']}cl1"

    def _get_ers_virtual_hostname(self, config: Dict[str, Any]) -> str:
        """Generate ERS virtual hostname according to SDAF pattern."""
        if config["custom_ers_virtual_hostname"]:
            return config["custom_ers_virtual_hostname"]

        return f"{config['sap_sid'].lower()}ers{config['ers_instance_number']}cl2"

    def _get_db_virtual_hostname(self, config: Dict[str, Any]) -> str:
        """Generate database virtual hostname according to SDAF pattern."""
        if config["custom_db_virtual_hostname"]:
            return config["custom_db_virtual_hostname"]

        return f"{config['sap_sid'].lower()}{config['db_sid'].lower()}db{config['db_instance_number']}cl"

    def _format_hosts_entry(self, ip_address: str, fqdn: str, hostname: str) -> str:
        """Format a single hosts file entry with proper spacing to match SDAF output."""
        # Use specific column widths to match the example output
        return f"{ip_address:<19}{fqdn:<81}{hostname:<17}"

    def format_hosts_entry(self, ip_address: str, fqdn: str, hostname: str) -> str:
        """Public filter for formatting a single hosts entry."""
        return self._format_hosts_entry(ip_address, fqdn, hostname)

    def validate_network_config(self, network_config: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate network configuration for SAP deployments.

        Args:
            network_config: Network configuration dictionary

        Returns:
            Validation results with status and messages
        """
        results = {"valid": True, "warnings": [], "errors": []}

        # Validate subnet CIDR formats
        for subnet_key in [
            "subnet_cidr_db",
            "subnet_cidr_storage",
            "subnet_cidr_client",
        ]:
            subnet_value = network_config.get(subnet_key)

            if subnet_value:
                try:
                    ipaddress.ip_network(subnet_value, strict=False)
                except (ipaddress.AddressValueError, ipaddress.NetmaskValueError) as e:
                    results["errors"].append(
                        f"Invalid {subnet_key}: {subnet_value} - {str(e)}"
                    )
                    results["valid"] = False

        # Check for overlapping subnets
        subnet_pairs = [
            ("subnet_cidr_db", "subnet_cidr_storage"),
            ("subnet_cidr_db", "subnet_cidr_client"),
            ("subnet_cidr_storage", "subnet_cidr_client"),
        ]

        for subnet1_key, subnet2_key in subnet_pairs:
            subnet1 = network_config.get(subnet1_key)
            subnet2 = network_config.get(subnet2_key)

            if subnet1 and subnet2:
                try:
                    net1 = ipaddress.ip_network(subnet1, strict=False)
                    net2 = ipaddress.ip_network(subnet2, strict=False)

                    if net1.overlaps(net2):
                        results["warnings"].append(
                            f"Subnets overlap: {subnet1_key}={subnet1} and {subnet2_key}={subnet2}"
                        )
                except (ipaddress.AddressValueError, ipaddress.NetmaskValueError):
                    pass  # Already handled above

        return results
