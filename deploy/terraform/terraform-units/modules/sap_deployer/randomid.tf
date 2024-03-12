# Generates random text for boot diagnostics storage account name
resource "random_id" "deployer" {
  byte_length = 4
}


// Generate random password if password is set as authentication type, and save in KV
resource "random_password" "deployer" {
  count                                = (
                                           local.enable_password
                                           && !local.pwd_exist
                                           && try(var.authentication.password, "") == ""
                                         ) ? 1 : 0

  length                               = 32
  min_upper                            = 2
  min_lower                            = 2
  min_numeric                          = 2
  special                              = true
  override_special                     = "_%@"
}
