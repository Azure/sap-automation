# Generates random text for boot diagnostics storage account name
resource "random_id" "deployer" {
  byte_length = 4
}
