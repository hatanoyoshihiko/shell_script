#!/bin/bash

if [ $# = 1 ]; then
  grep -v '^\s*#\|^\s*$' $1 
else
  echo "ARGUMENT ERROR"
fi
