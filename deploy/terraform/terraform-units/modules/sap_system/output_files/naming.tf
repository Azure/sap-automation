
resource "local_file" "naming" {
  count                = var.save_naming_information ? 1 : 0
  content              = jsonencode(var.naming)
  filename             = format("%s/%s_resource_names.json", path.cwd, var.sap_sid)
  file_permission      = "0660"
  directory_permission = "0770"
}
