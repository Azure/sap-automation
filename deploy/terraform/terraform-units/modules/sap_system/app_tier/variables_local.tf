
locals {
  // Imports Disk sizing sizing information

  default_filepath = format("%s%s", path.module, "/../../../../../configs/app_sizes.json")
  custom_sizing    = length(var.custom_disk_sizes_filename) > 0

  // Imports application tier sizing information
  file_name = local.custom_sizing ? (
    fileexists(var.custom_disk_sizes_filename) ? (
      var.custom_disk_sizes_filename) : (
      format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
    )) : (
    local.default_filepath

  )

  sizes = jsondecode(file(local.file_name))

  faults            = jsondecode(file(format("%s%s", path.module, "/../../../../../configs/max_fault_domain_count.json")))
  resource_suffixes = var.naming.resource_suffixes

  //Allowing changing the base for indexing, default is zero-based indexing, if customers want the first disk to start with 1 they would change this
  offset = var.options.resource_offset

  faultdomain_count = try(tonumber(compact(
    [for pair in local.faults :
      upper(pair.Location) == upper(var.infrastructure.region) ? pair.MaximumFaultDomainCount : ""
  ])[0]), 2)

  sid    = upper(var.application.sid)
  prefix = trimspace(var.naming.prefix.SDU)
  // Resource group
  resource_group_exists = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  rg_name = local.resource_group_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    coalesce(
      try(var.infrastructure.resource_group.name, ""),
      format("%s%s%s",
        var.naming.resource_prefixes.sdu_rg,
        local.prefix,
        local.resource_suffixes.sdu_rg
      )
    )
  )

  sid_auth_type = upper(local.app_ostype) == "LINUX" ? (
    try(var.application.authentication.type, "key")) : (
    "password"
  )
  enable_auth_password = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key      = local.enable_deployment && local.sid_auth_type == "key"

  authentication = {
    "type"     = local.sid_auth_type
    "username" = var.sid_username
    "password" = var.sid_password
  }

  ##############################################################################################
  #
  #  App subnet - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  application_subnet_defined = length(try(var.infrastructure.vnets.sap.subnet_app, {})) > 0
  application_subnet_prefix = local.application_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_app.prefix, "")) : (
    ""
  )

  application_subnet_arm_id = local.application_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_app.arm_id, "")
    ) : (
    var.landscape_tfstate.app_subnet_id
  )
  application_subnet_exists = length(local.application_subnet_arm_id) > 0

  application_subnet_name = local.application_subnet_defined ? (
    local.application_subnet_exists ? (
      split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[10]) : (
      length(var.infrastructure.vnets.sap.subnet_app.name) > 0 ? (
        var.infrastructure.vnets.sap.subnet_app.name) : (
        format("%s%s%s%s",
          var.naming.resource_prefixes.app_subnet,
          length(local.prefix) > 0 ? (
            local.prefix) : (
            var.infrastructure.environment
          ),
          var.naming.separator,
          local.resource_suffixes.app_subnet
        )
    ))) : (
    ""
  )

  ##############################################################################################
  #
  #  Application subnet NSG - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  application_subnet_nsg_defined = length(try(var.infrastructure.vnets.sap.subnet_app.nsg, {})) > 0

  application_subnet_nsg_arm_id = local.application_subnet_nsg_defined ? (
    try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, "")) : (
    var.landscape_tfstate.app_nsg_id
  )

  application_subnet_nsg_exists = length(local.application_subnet_nsg_arm_id) > 0
  application_subnet_nsg_name = local.application_subnet_nsg_defined ? (
    local.application_subnet_nsg_exists ? (
      split("/", var.infrastructure.vnets.sap.subnet_app.nsg.arm_id)[8]) : (
      length(var.infrastructure.vnets.sap.subnet_app.nsg.name) > 0 ? (
        var.infrastructure.vnets.sap.subnet_app.nsg.name) : (
        format("%s%s%s%s",
          var.naming.resource_prefixes.app_subnet_nsg,
          length(local.prefix) > 0 ? (
            local.prefix) : (
            var.infrastructure.environment
          ),
          var.naming.separator,
          local.resource_suffixes.app_subnet_nsg
        )
    ))) : (
    ""
  )

  ##############################################################################################
  #
  #  Web subnet - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  web_subnet_defined = length(try(var.infrastructure.vnets.sap.subnet_web, {})) > 0
  web_subnet_prefix  = local.web_subnet_defined ? try(var.infrastructure.vnets.sap.subnet_web.prefix, "") : ""

  web_subnet_arm_id = local.web_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_web.arm_id, "")
    ) : (
    var.landscape_tfstate.web_subnet_id
  )
  web_subnet_exists = length(local.web_subnet_arm_id) > 0

  web_subnet_name = local.web_subnet_defined ? (
    local.web_subnet_exists ? (
      split("/", var.infrastructure.vnets.sap.subnet_web.arm_id)[10]) : (
      length(var.infrastructure.vnets.sap.subnet_web.name) > 0 ? (
        var.infrastructure.vnets.sap.subnet_web.name) : (
        format("%s%s%s%s",
          var.naming.resource_prefixes.web_subnet,
          length(local.prefix) > 0 ? (
            local.prefix) : (
            var.infrastructure.environment
          ),
          var.naming.separator,
          local.resource_suffixes.web_subnet
        )
    ))) : (
    ""
  )

  ##############################################################################################
  #
  #  Web subnet NSG - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  web_subnet_nsg_defined = length(try(var.infrastructure.vnets.sap.subnet_web.nsg, {})) > 0
  web_subnet_nsg_arm_id = local.web_subnet_nsg_defined ? (
    coalesce(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, var.landscape_tfstate.web_nsg_id, "")) : (
    ""
  )

  web_subnet_nsg_exists = length(local.web_subnet_nsg_arm_id) > 0
  web_subnet_nsg_name = local.web_subnet_nsg_defined ? (
    local.web_subnet_nsg_exists ? (
      split("/", var.infrastructure.vnets.sap.subnet_web.nsg.arm_id)[8]) : (
      length(var.infrastructure.vnets.sap.subnet_web.nsg.name) > 0 ? (
        var.infrastructure.vnets.sap.subnet_web.nsg.name) : (
        format("%s%s%s%s",
          var.naming.resource_prefixes.web_subnet_nsg,
          length(local.prefix) > 0 ? (
            local.prefix) : (
            var.infrastructure.environment
          ),
          var.naming.separator,
          local.resource_suffixes.web_subnet_nsg
        )
    ))) : (
    ""
  )

  web_subnet_deployed = try(local.web_subnet_defined ? (
    local.web_subnet_exists ? (
      data.azurerm_subnet.subnet_sap_web[0]) : (
      azurerm_subnet.subnet_sap_web[0]
    )) : (
    local.application_subnet_exists ? (
      data.azurerm_subnet.subnet_sap_app[0]) : (
      azurerm_subnet.subnet_sap_app[0]
    )), null
  )

  web_subnet_nsg_deployed = try(local.web_subnet_defined ? (
    local.web_subnet_nsg_exists ? (
      data.azurerm_network_security_group.nsg_web[0]) : (
      azurerm_network_security_group.nsg_web[0]
    )) : (
    local.application_subnet_nsg_exists ? (
      data.azurerm_network_security_group.nsg_app[0]) : (
      azurerm_network_security_group.nsg_app[0]
    )), null
  )

  firewall_exists          = length(var.firewall_id) > 0
  enable_deployment        = var.application.enable_deployment && length(try(var.landscape_tfstate.vnet_sap_arm_id, "")) > 0
  scs_instance_number      = var.application.scs_instance_number
  ers_instance_number      = var.application.ers_instance_number
  scs_high_availability    = var.application.scs_high_availability
  application_server_count = var.application.application_server_count
  scs_server_count         = var.application.scs_server_count * (local.scs_high_availability ? 2 : 1)
  enable_scs_lb_deployment = local.enable_deployment ? (
    (
      local.scs_server_count > 0 &&
      (var.use_loadbalancers_for_standalone_deployments || local.scs_server_count > 1)
    )) : (
    false
  )

  webdispatcher_count = var.application.webdispatcher_count
  enable_web_lb_deployment = (
    local.webdispatcher_count > 0 &&
    (var.use_loadbalancers_for_standalone_deployments || local.webdispatcher_count > 1)
  )

  app_nic_ips           = try(var.application.app_nic_ips, [])
  app_nic_secondary_ips = try(var.application.app_nic_secondary_ips, [])
  app_admin_nic_ips     = try(var.application.app_admin_nic_ips, [])

  scs_lb_ips            = try(var.application.scs_lb_ips, [])
  scs_nic_ips           = try(var.application.scs_nic_ips, [])
  scs_nic_secondary_ips = try(var.application.scs_nic_secondary_ips, [])
  scs_admin_nic_ips     = try(var.application.scs_admin_nic_ips, [])

  web_lb_ips            = try(var.application.web_lb_ips, [])
  web_nic_ips           = try(var.application.web_nic_ips, [])
  web_nic_secondary_ips = try(var.application.web_nic_secondary_ips, [])
  web_admin_nic_ips     = try(var.application.web_admin_nic_ips, [])

  app_size = var.application.app_sku
  scs_size = length(var.application.scs_sku) > 0 ? var.application.scs_sku : local.app_size
  web_size = length(var.application.web_sku) > 0 ? var.application.web_sku : local.app_size

  vm_sizing_dictionary_key = length(var.application.vm_sizing_dictionary_key) > 0 ? (
    var.application.vm_sizing_dictionary_key) : (
    length(local.app_size) > 0 ? (
      "Optimized") : (
      "Default"
    )
  )

  // OS image for all Application Tier VMs
  // If custom image is used, we do not overwrite os reference with default value

  app_custom_image = length(try(var.application.app_os.source_image_id, "")) > 0
  app_ostype = upper(try(var.application.app_os.offer, "")) == "WINDOWSSERVER" ? (
    "WINDOWS") : (
    try(var.application.app_os.os_type, "LINUX")
  )

  app_os = {
    os_type         = local.app_ostype
    source_image_id = local.app_custom_image ? var.application.app_os.source_image_id : ""
    publisher = local.app_custom_image ? (
      "") : (
      length(try(var.application.app_os.publisher, "")) > 0 ? (
        var.application.app_os.publisher) : (
        "SUSE"
      )
    )
    offer = local.app_custom_image ? (
      "") : (
      length(try(var.application.app_os.offer, "")) > 0 ? (
        var.application.app_os.offer) : (
        "sles-sap-15-sp3"
      )
    )
    sku = local.app_custom_image ? (
      "") : (
      length(try(var.application.app_os.sku, "")) > 0 ? (
        var.application.app_os.sku) : (
        "gen2"
      )
    )
    version = local.app_custom_image ? (
      "") : (
      length(try(var.application.app_os.version, "")) > 0 ? (
        var.application.app_os.version) : (
        "latest"
      )
    )
  }

  // OS image for all SCS VMs
  // If custom image is used, we do not overwrite os reference with default value
  // If no publisher or no custom image is specified use the custom image from the app if specified
  scs_custom_image = length(try(var.application.scs_os.source_image_id, "")) > 0
  scs_ostype = upper(try(var.application.scs_os.offer, "")) == "WINDOWSSERVER" ? (
    "WINDOWS") : (
    try(var.application.scs_os.os_type, local.app_ostype)
  )

  scs_os = {
    os_type = local.scs_ostype
    source_image_id = local.scs_custom_image ? (
      var.application.scs_os.source_image_id) : (
      ""
    )
    publisher = local.scs_custom_image ? (
      "") : (
      length(try(var.application.scs_os.publisher, "")) > 0 ? (
        var.application.scs_os.publisher) : (
        "SUSE"
      )
    )
    offer = local.scs_custom_image ? (
      "") : (
      length(try(var.application.scs_os.offer, "")) > 0 ? (
        var.application.scs_os.offer) : (
        "sles-sap-15-sp3"
      )
    )
    sku = local.scs_custom_image ? (
      "") : (
      length(try(var.application.scs_os.sku, "")) > 0 ? (
        var.application.scs_os.sku) : (
        "gen2"
      )
    )
    version = local.scs_custom_image ? (
      "") : (
      length(try(var.application.scs_os.version, "")) > 0 ? (
        var.application.scs_os.version) : (
      "latest")
    )
  }

  // OS image for all WebDispatcher VMs
  // If custom image is used, we do not overwrite os reference with default value
  // If no publisher or no custom image is specified use the custom image from the app if specified
  web_custom_image = length(try(var.application.web_os.source_image_id, "")) > 0
  web_ostype = upper(try(var.application.web_os.offer, "")) == "WINDOWSSERVER" ? (
    "WINDOWS") : (
    try(var.application.web_os.os_type, local.app_ostype)
  )
  web_os = {
    os_type = local.web_ostype
    source_image_id = local.web_custom_image ? (
      var.application.web_os.source_image_id) : (
      ""
    )
    publisher = local.web_custom_image ? (
      "") : (
      length(try(var.application.web_os.publisher, "")) > 0 ? (
        var.application.web_os.publisher) : (
        "SUSE"
      )
    )
    offer = local.web_custom_image ? (
      "") : (
      length(try(var.application.web_os.offer, "")) > 0 ? (
        var.application.web_os.offer) : (
        "sles-sap-15-sp3"
      )
    )
    sku = local.web_custom_image ? (
      "") : (
      length(try(var.application.web_os.sku, "")) > 0 ? (
        var.application.web_os.sku) : (
        "gen2"
      )
    )
    version = local.web_custom_image ? (
      "") : (
      length(try(var.application.web_os.version, "")) > 0 ? (
        var.application.web_os.version) : (
        "latest"
      )
    )
  }

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  linux_ip_offsets = {
    scs_lb = 4
    scs_vm = 6
    app_vm = 10
    web_lb = local.web_subnet_defined ? (4 + 1) : 6
    web_vm = local.web_subnet_defined ? (10) : 50
  }

  windows_ip_offsets = {
    scs_lb = 4
    scs_vm = 6 + 2 # Windows HA SCS may require 4 IPs
    app_vm = 10 + 2
    web_lb = local.web_subnet_defined ? (4 + 1) : 6 + 2
    web_vm = local.web_subnet_defined ? (10) : 50
  }

  win_ha_scs = local.scs_server_count > 0 && (local.scs_high_availability && upper(local.scs_ostype) == "WINDOWS")

  ip_offsets = local.scs_ostype == "WINDOWS" ? local.windows_ip_offsets : local.linux_ip_offsets

  admin_ip_offsets = {
    app_vm = 14
    scs_vm = 10
    web_vm = 50
  }


  // Default VM config should be merged with any the user passes in
  app_sizing = local.enable_deployment && local.application_server_count > 0 ? (
    lookup(local.sizes.app, local.vm_sizing_dictionary_key)) : (
    null
  )

  scs_sizing = local.enable_deployment ? (
    local.scs_high_availability ? lookup(local.sizes.scsha, local.vm_sizing_dictionary_key) : lookup(local.sizes.scs, local.vm_sizing_dictionary_key)
    ) : (
    null
  )

  web_sizing = local.enable_deployment && local.webdispatcher_count > 0 ? (
    lookup(local.sizes.web, local.vm_sizing_dictionary_key)) : (
    null
  )

  // Ports used for specific ASCS, ERS and Web dispatcher
  lb_ports = {
    "scs" = [
      3200 + tonumber(var.application.scs_instance_number),          // e.g. 3201
      3600 + tonumber(var.application.scs_instance_number),          // e.g. 3601
      3900 + tonumber(var.application.scs_instance_number),          // e.g. 3901
      8100 + tonumber(var.application.scs_instance_number),          // e.g. 8101
      50013 + (tonumber(var.application.scs_instance_number) * 100), // e.g. 50113
      50014 + (tonumber(var.application.scs_instance_number) * 100), // e.g. 50114
      50016 + (tonumber(var.application.scs_instance_number) * 100), // e.g. 50116
    ]

    "ers" = [
      3200 + tonumber(var.application.ers_instance_number),          // e.g. 3202
      3300 + tonumber(var.application.ers_instance_number),          // e.g. 3302
      50013 + (tonumber(var.application.ers_instance_number) * 100), // e.g. 50213
      50014 + (tonumber(var.application.ers_instance_number) * 100), // e.g. 50214
      50016 + (tonumber(var.application.ers_instance_number) * 100), // e.g. 50216
    ]

    "web" = [
      80,
      3200
    ]
  }

  // Ports used for ASCS, ERS and Web dispatcher NSG rules
  nsg_ports = {
    "web" = [
      {
        "priority" = "101",
        "name"     = "SSH",
        "port"     = "22"
      },
      {
        "priority" = "102",
        "name"     = "HTTP",
        "port"     = "80"
      },
      {
        "priority" = "103",
        "name"     = "HTTPS",
        "port"     = "443"
      },
      {
        "priority" = "104",
        "name"     = "sapinst",
        "port"     = "4237"
      },
      {
        "priority" = "105",
        "name"     = "WebDispatcher",
        "port"     = "44300"
      }
    ]
  }

  // Ports used for the health probes.
  // Where Instance Number is nn:
  // SCS (index 0) - 620nn
  // ERS (index 1) - 621nn
  hp_ports = [
    62000 + tonumber(var.application.scs_instance_number),
    62100 + tonumber(var.application.ers_instance_number)
  ]


  // Zones
  app_zones            = try(var.application.app_zones, [])
  app_zonal_deployment = length(local.app_zones) > 0 ? true : false
  app_zone_count       = length(local.app_zones)
  //If we deploy more than one server in zone put them in an availability set unless specified otherwise
  use_app_avset = local.application_server_count > 0 && !var.application.app_no_avset ? (
    true && local.enable_deployment) : (
    false && local.enable_deployment
  )

  scs_zones            = try(var.application.scs_zones, [])
  scs_zonal_deployment = length(local.scs_zones) > 0 ? true : false
  scs_zone_count       = length(local.scs_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_scs_avset = local.scs_server_count > 0 && (!var.application.scs_no_avset) ? (
    !local.scs_zonal_deployment || local.scs_server_count != local.scs_zone_count) : (
    false
  )

  web_zones            = try(var.application.web_zones, [])
  web_zonal_deployment = length(local.web_zones) > 0 ? true : false
  web_zone_count       = length(local.web_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_web_avset = local.webdispatcher_count > 0 && !var.application.web_no_avset ? (
    local.enable_deployment && (!local.web_zonal_deployment || local.webdispatcher_count != local.web_zone_count)) : (
    false
  )

  winha_ips = upper(local.scs_ostype) == "WINDOWS" ? [
    {
      name = format("%s%s%s%s",
        var.naming.resource_prefixes.scs_clst_feip,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.scs_clst_feip
      )
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      private_ip_address = length(try(local.scs_lb_ips[2], "")) > 0 ? (
        local.scs_lb_ips[2]) : (
        var.application.use_DHCP ? (
        null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 2 + local.ip_offsets.scs_lb))
      )
      private_ip_address_allocation = length(try(local.scs_lb_ips[2], "")) > 0 ? "Static" : "Dynamic"

    },
    {
      name = format("%s%s%s%s",
        var.naming.resource_prefixes.scs_fs_feip,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.scs_fs_feip
      )
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      private_ip_address = length(try(local.scs_lb_ips[3], "")) > 0 ? (
        local.scs_lb_ips[3]) : (
        var.application.use_DHCP ? (
        null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 3 + local.ip_offsets.scs_lb))
      )
      private_ip_address_allocation = length(try(local.scs_lb_ips[3], "")) > 0 ? "Static" : "Dynamic"
    }
  ] : []

  std_ips = [
    {
      name = format("%s%s%s%s",
        var.naming.resource_prefixes.scs_alb_feip,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.scs_alb_feip
      )
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      private_ip_address = length(try(local.scs_lb_ips[0], "")) > 0 ? (
        local.scs_lb_ips[0]) : (
        var.application.use_DHCP ? (
        null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 0 + local.ip_offsets.scs_lb))
      )
      private_ip_address_allocation = length(try(local.scs_lb_ips[0], "")) > 0 ? "Static" : "Dynamic"
    },
    {
      name = format("%s%s%s%s",
        var.naming.resource_prefixes.scs_ers_feip,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.scs_ers_feip
      )
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      private_ip_address = length(try(local.scs_lb_ips[1], "")) > 0 ? (
        local.scs_lb_ips[1]) : (
        var.application.use_DHCP ? (
        null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 1 + local.ip_offsets.scs_lb))
      )
      private_ip_address_allocation = length(try(local.scs_lb_ips[1], "")) > 0 ? "Static" : "Dynamic"
    },
  ]

  fpips = (local.scs_high_availability && upper(local.scs_ostype) == "WINDOWS") ? (
    concat(local.std_ips, local.winha_ips)) : (
    local.std_ips
  )


  //PPG control flags
  app_no_ppg = var.application.app_no_ppg
  scs_no_ppg = var.application.scs_no_ppg
  web_no_ppg = var.application.web_no_ppg

  dns_label               = try(var.landscape_tfstate.dns_label, "")

  deploy_route_table = local.enable_deployment && length(var.route_table_id) > 0

  application_primary_ips = [
    {
      name = "IPConfig1"
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      nic_ips                       = local.app_nic_ips
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
      offset                        = 0
      primary                       = true
    }
  ]

  application_secondary_ips = [
    {
      name = "IPConfig2"
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      nic_ips                       = local.app_nic_secondary_ips
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
      offset                        = local.application_server_count
      primary                       = false
    }
  ]

  application_ips = (var.use_secondary_ips) ? (
    flatten(concat(local.application_primary_ips, local.application_secondary_ips))) : (
    local.application_primary_ips
  )

  scs_primary_ips = [
    {
      name = "IPConfig1"
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      nic_ips                       = local.scs_nic_ips
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
      offset                        = 0
      primary                       = true
    }
  ]

  scs_secondary_ips = [
    {
      name = "IPConfig2"
      subnet_id = local.enable_deployment ? (
        local.application_subnet_exists ? (
          data.azurerm_subnet.subnet_sap_app[0].id) : (
          azurerm_subnet.subnet_sap_app[0].id
        )) : (
        ""
      )
      nic_ips                       = local.scs_nic_secondary_ips
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
      offset                        = local.scs_server_count
      primary                       = false
    }
  ]

  scs_ips = (var.use_secondary_ips) ? (
    flatten(concat(local.scs_primary_ips, local.scs_secondary_ips))) : (
    local.scs_primary_ips
  )

  web_dispatcher_primary_ips = [
    {
      name      = "IPConfig1"
      subnet_id = local.enable_deployment ? local.web_subnet_deployed.id : ""

      nic_ips                       = local.web_nic_ips
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
      offset                        = 0
      primary                       = true
    }
  ]

  web_dispatcher_secondary_ips = [
    {
      name                          = "IPConfig2"
      subnet_id                     = local.enable_deployment ? local.web_subnet_deployed.id : ""
      nic_ips                       = local.web_nic_secondary_ips
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
      offset                        = local.webdispatcher_count
      primary                       = false
    }
  ]

  web_dispatcher_ips = (var.use_secondary_ips) ? (
    flatten(concat(local.web_dispatcher_primary_ips, local.web_dispatcher_secondary_ips))) : (
    local.web_dispatcher_primary_ips
  )

}
