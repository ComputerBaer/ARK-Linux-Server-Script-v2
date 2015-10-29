#!/bin/bash

echo -n "Generating new Checksums ... "

# Base Directory Scripts
md5sum arkserver.sh checksums.sh > checksums
# Sample Configuration File
md5sum configuration-sample.ini >> checksums
# Other Script Files
md5sum .script/*.sh >> checksums

echo "Done!"
