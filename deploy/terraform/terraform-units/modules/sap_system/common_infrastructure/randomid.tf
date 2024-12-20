# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Generates random text for boot diagnostics storage account name
resource "random_id" "random_id" {
  byte_length = 4

}
