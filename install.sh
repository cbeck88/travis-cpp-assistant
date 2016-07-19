#!/bin/bash

set -e
set -x

retry()
{
  $* && exit
  $* && exit
  $*
}

  echo "LLVM = " "${LLVM_VERSION}"
  echo "Boost = " "${BOOST_VERSION}"

  ############################################################################
  # All the dependencies are installed in ${TRAVIS_BUILD_DIR}/deps/
  ############################################################################
  export DEPS_DIR="${TRAVIS_BUILD_DIR}/deps"
  mkdir -p ${DEPS_DIR} && cd ${DEPS_DIR}

  ############################################################################
  # Setup default versions and override compiler if needed
  ############################################################################
  if [[ "${LLVM_VERSION}" == "default" ]]; then LLVM_VERSION=3.8.0; fi
  if [[ "${BOOST_VERSION}" == "default" ]]; then BOOST_VERSION=1.60.0; fi

  ############################################################################
  # Install Boost headers
  ############################################################################
    if [[ "${BOOST_VERSION}" != "" ]]; then
      export BOOST_DIR=${DEPS_DIR}/boost-${BOOST_VERSION}
      if [[ -z "$(ls -A ${BOOST_DIR})" ]]; then
        if [[ "${BOOST_VERSION}" == "trunk" ]]; then
          BOOST_URL="http://github.com/boostorg/boost.git"
          retry git clone --depth 1 --recursive --quiet ${BOOST_URL} ${BOOST_DIR} || exit 1
          (cd ${BOOST_DIR} && ./bootstrap.sh && ./b2 headers)
        else
          BOOST_URL="http://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION}/boost_${BOOST_VERSION//\./_}.tar.gz"
          mkdir -p ${BOOST_DIR}
          { retry wget --quiet -O - ${BOOST_URL} | tar --strip-components=1 -xz -C ${BOOST_DIR}; } || exit 1
        fi
      fi
      export BOOST_ROOT="${BOOST_DIR}"
    fi
  ############################################################################
  # Install a recent CMake (unless already installed on OS X)
  ############################################################################
    if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
      CMAKE_URL="http://www.cmake.org/files/v3.5/cmake-3.5.2-Linux-x86_64.tar.gz"
      mkdir cmake && retry wget --no-check-certificate --quiet -O - ${CMAKE_URL} | tar --strip-components=1 -xz -C cmake
      export PATH=${DEPS_DIR}/cmake/bin:${PATH}
    else
      if ! brew ls --version cmake &>/dev/null; then brew install cmake; fi
    fi
  ############################################################################
  # Install Boost.Build
  ############################################################################
    if [[ "${BOOST_BUILD}" == "true" ]]; then
      (cd ${BOOST_DIR}/tools/build && ./bootstrap.sh && ./b2 install --prefix=${DEPS_DIR}/b2)
      export PATH=${DEPS_DIR}/b2/bin:${PATH}
    fi
  ############################################################################
  # Install Clang, libc++ and libc++abi
  ############################################################################
    if [[ "${LLVM_VERSION}" != "" ]]; then
      LLVM_DIR=${DEPS_DIR}/llvm-${LLVM_VERSION}
      if [[ -z "$(ls -A ${LLVM_DIR})" ]]; then
        LLVM_URL="http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz"
        LIBCXX_URL="http://llvm.org/releases/${LLVM_VERSION}/libcxx-${LLVM_VERSION}.src.tar.xz"
        LIBCXXABI_URL="http://llvm.org/releases/${LLVM_VERSION}/libcxxabi-${LLVM_VERSION}.src.tar.xz"
        CLANG_URL="http://llvm.org/releases/${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz"
        mkdir -p ${LLVM_DIR} ${LLVM_DIR}/build ${LLVM_DIR}/projects/libcxx ${LLVM_DIR}/projects/libcxxabi ${LLVM_DIR}/clang
        retry wget --quiet -O - ${LLVM_URL}      | tar --strip-components=1 -xJ -C ${LLVM_DIR}
        retry wget --quiet -O - ${LIBCXX_URL}    | tar --strip-components=1 -xJ -C ${LLVM_DIR}/projects/libcxx
        retry wget --quiet -O - ${LIBCXXABI_URL} | tar --strip-components=1 -xJ -C ${LLVM_DIR}/projects/libcxxabi
        retry wget --quiet -O - ${CLANG_URL}     | tar --strip-components=1 -xJ -C ${LLVM_DIR}/clang
        (cd ${LLVM_DIR}/build && cmake .. -DCMAKE_INSTALL_PREFIX=${LLVM_DIR}/install -DCMAKE_CXX_COMPILER=clang++)
        (cd ${LLVM_DIR}/build/projects/libcxx && make install -j2)
        (cd ${LLVM_DIR}/build/projects/libcxxabi && make install -j2)
      fi
      export CXXFLAGS="-nostdinc++ -isystem ${LLVM_DIR}/install/include/c++/v1"
      export LDFLAGS="-L ${LLVM_DIR}/install/lib -l c++ -l c++abi"
      export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LLVM_DIR}/install/lib"
      export PATH="${LLVM_DIR}/clang/bin:${PATH}"
    fi

  ############################################################################
  # Install gcc
  ############################################################################
    if [[ "${GCC_VERSION}" != "" ]]; then
      GCC_DIR=${DEPS_DIR}/gcc-${GCC_VERSION}
      GCC_OBJ_DIR=${DEPS_DIR}/gcc-${GCC_VERSION}-obj
      GCC_SRC_DIR=${DEPS_DIR}/gcc-${GCC_VERSION}-src
      if [[ -z "$(ls -A ${GCC_DIR})" ]]; then
        GCC_URL=http://mirrors-usa.go-parts.com/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
        mkdir -p ${GCC_DIR} ${GCC_SRC_DIR} ${GCC_OBJ_DIR}
        retry wget --quiet -O - ${GCC_URL} | tar --strip-components=1 -xJ -C ${GCC_SRC_DIR}
        cd ${GCC_SRC_DIR}
        ./contrib/download_prerequisites
        cd ${GCC_OBJ_DIR}
        ${GCC_SRC_DIR}/configure --prefix=${GCC_DIR} --enable-languages=c,c++ --disable-multilib
        make install -j2
      fi
      cd ${GCC_DIR} && ls -a
      export CXXFLAGS="-nostdinc++ -isystem ${GCC_DIR}/include/c++"
      export LDFLAGS="-L ${GCC_DIR}/lib -l libstdc++"
      export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GCC_DIR}/lib"
      export PATH="${GCC_DIR}/bin:$PATH"
    fi

  ###
  # Change back to build directory
  ##

  cd ${TRAVIS_BUILD_DIR}
