# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

// Generates random text for unique naming
resource "random_id" "random_id" {
  byte_length = 4
}
