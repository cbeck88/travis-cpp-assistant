#!/bin/bash
set -x

${CXX} -I${BOOST_ROOT} ${CXXFLAGS} main.cpp -o a.out ${LDFLAGS}
./a.out $*
