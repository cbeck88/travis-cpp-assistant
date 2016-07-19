#!/bin/bash
set -e
set -x

${CXX} -I${BOOST_ROOT} main.cpp
./a.out
rm a.out
