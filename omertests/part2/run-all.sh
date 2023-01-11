#!/usr/bin/env bash

set -eu

cd "$(dirname "$BASH_SOURCE")"
for EXAMPLE in examples/*; do
    ./run.sh "$EXAMPLE"
done
echo "All tests passed"
