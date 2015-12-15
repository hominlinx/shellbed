#!/bin/bash

cat <<- EOF > output
echo "this is output"
echo $1
EOF
