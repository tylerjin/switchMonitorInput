#!/usr/bin/env python3
"""LG webOS 26 compatibility wrapper for the installed bscpylgtv CLI.

LG firmware rejects the legacy signed registration manifest. This wrapper
substitutes the unsigned generic permissions manifest in process memory;
the installed library is left unchanged. A new TV pairing approval is
required on first successful connection.
"""
from copy import deepcopy
from bscpylgtv import webos_client
from bscpylgtv.manifest import MANIFEST

manifest = deepcopy(MANIFEST)
manifest.pop("signatures", None)
manifest.pop("signed", None)
webos_client.MANIFEST = manifest

from bscpylgtv.utils import bscpylgtvcommand

if __name__ == "__main__":
    bscpylgtvcommand()
