#!/bin/bash
set -x
set -e

${CXX} -I${BOOST_ROOT} ${CXXFLAGS} main.cpp -o a.out ${LDFLAGS}
./a.out $*
