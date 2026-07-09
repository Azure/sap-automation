#!/usr/bin/env python3
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import sys
import os

# Ensure the current directory is in the path so we can import the package
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sdaf import main

if __name__ == "__main__":
    main()
