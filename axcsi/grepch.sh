#!/bin/bash
set -x;

echo "($1) ($2)"
find $2 -name '*.c' -o -name '*.h' -o -name '*.m' | xargs grep -ir --color $1
