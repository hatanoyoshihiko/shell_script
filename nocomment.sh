#!/bin/bash

if [ $# = 1 ]; then
  grep -v '^\s*\(#\|$\)' $1
else
  echo "ARGUMENT ERROR"
fi
