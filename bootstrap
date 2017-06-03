#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for dir in $SCRIPT_DIR/*; do
	test -d $dir && test -f $dir/install.sh && $dir/install.sh
done
