locals {

  ppg_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("-z%s%s", local.zones[idx], "-ppg")
    ]) : (
    [
      length(trimspace(var.custom_prefix)) == 0 ? format("%s%s", local.sdu_name, "-ppg") : format("%s", "-ppg")
    ]
  )

  app_ppg_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("-z%s%s", local.zones[idx], "-app-ppg")
    ]) : (
    [
      length(trimspace(var.custom_prefix)) == 0 ? format("%s%s", local.sdu_name, "-app-ppg") : format("%s", "-app-ppg")
    ]
  )

  app_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s_%s", local.zones[idx], "app-avset")
    ]) : (
    [format("%s", "app-avset")]
  )

  scs_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s_%s", local.zones[idx], "scs-avset")
    ]) : (
    [format("%s", "scs-avset")]
  )

  web_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s_%s", local.zones[idx], "web-avset")
    ]) : (
    [format("%s", "web-avset")]
  )

  db_avset_names = local.zonal_deployment ? (
    [for idx in range(length(local.zones)) :
      format("z%s_%s", local.zones[idx], "db-avset")
    ]) : (
    [format("%s", "db-avset")]
  )

}
