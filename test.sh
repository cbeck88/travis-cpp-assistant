#!/bin/bash
set -e
set -x

${CXX} -I${BOOST_ROOT} ${CXXFLAGS} main.cpp -o a.out ${LDFLAGS}
./a.out
rm a.out
