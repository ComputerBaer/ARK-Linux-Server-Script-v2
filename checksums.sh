#!/bin/bash

echo -n "Generating new Checksums ... "

md5sum *.sh > checksums
md5sum .script/*.sh >> checksums

echo "Done!"
