#!/bin/bash

echo -n "Generating new Checksums ... "

# Base Directory Scripts
# md5sum arkserver.sh checksums.sh dependencies.sh > checksums
# End users do not need checksums.sh and developers use git
md5sum arkserver.sh dependencies.sh > checksums

# Sample Script Configuration File
md5sum configuration-sample.ini >> checksums
# Sample Game Configuration File
md5sum GameUserSettings-sample.ini >> checksums

# Other Script Files
find .script/ -type f -exec md5sum "{}" \; >> checksums

echo "Done!"
