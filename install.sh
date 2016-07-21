#!/bin/bash

#####
# Versions of travis_retry and travis_wait
#####

travis_retry() {
  echo "Command: $@"
  $* && return
  $* && return
  $* || exit 1
}

# Like "travis_wait", but when the time limit is reached, kills the process
# and reports success, rather than an error
travis_limit_time() {
  local cmd="$@"
  echo "Command: ${cmd}"
  local log_file=travis_wait_$$.log

  $cmd 2>&1 >$log_file &
  local cmd_pid=$!

  travis_jigger $! $cmd &
  local jigger_pid=$!
  local result

  { wait $cmd_pid 2>/dev/null; result=$?; ps -p$jigger_pid 2>&1>/dev/null && kill $jigger_pid; } || return 0
  if [[ $result -eq 0 ]]; then echo "Command succeeded: ${cmd}"; else echo "Command failed: ${cmd}"; fi
  return $result
}

travis_jigger() {
  local timeout=40 # in minutes
  local count=0

  local cmd_pid=$1
  shift

  while [ $count -lt $timeout ]; do
    count=$(($count + 1))
    echo -e "\033[0mStill running ($count of $timeout): $@"
    sleep 60
  done

  echo -e "\n\033[31;1mTimeout reached. Terminating $@\033[0m\n"
  kill -9 $cmd_pid
}


###
# Main script
###

  echo "Requested: "
  echo "BOOST_VERSION = " "${BOOST_VERSION}"
  echo "GCC_VERSION = " "${GCC_VERSION}"
  echo "LLVM_VERSION = " "${LLVM_VERSION}"
  echo "BOOST_BUILD = " "${BOOST_BUILD}"
  echo

  ############################################################################
  # All the dependencies are installed in ${TRAVIS_BUILD_DIR}/deps/
  ############################################################################
  export DEPS_DIR="${TRAVIS_BUILD_DIR}/deps"
  mkdir -p ${DEPS_DIR} && cd ${DEPS_DIR}

  ############################################################################
  # Setup default versions and override compiler if needed
  ############################################################################

  if [[ "${LLVM_VERSION}" == "default" ]]; then export LLVM_VERSION=3.8.0; fi
  if [[ "${BOOST_VERSION}" == "default" ]]; then export BOOST_VERSION=1.60.0; fi

  # If the user doesn't have major.minor.patch, then add a patch_level
  if [[ "${LLVM_VERSION}" == "3.5" ]]; then export LLVM_VERSION=3.5.2; fi
  if [[ "${LLVM_VERSION}" == "3.6" ]]; then export LLVM_VERSION=3.6.2; fi
  if [[ "${LLVM_VERSION}" == "3.7" ]]; then export LLVM_VERSION=3.7.1; fi
  if [[ "${LLVM_VERSION}" == "3.8" ]]; then export LLVM_VERSION=3.8.0; fi
  if [[ "${LLVM_VERSION}" == "3.9" ]]; then export LLVM_VERSION=3.9.0; fi

  if [[ "${GCC_VERSION}" == "4.8" ]]; then export GCC_VERSION=4.8.4; fi
  if [[ "${GCC_VERSION}" == "4.9" ]]; then export GCC_VERSION=4.9.3; fi
  if [[ "${GCC_VERSION}" == "5.1" ]]; then export GCC_VERSION=5.1.0; fi
  if [[ "${GCC_VERSION}" == "5.2" ]]; then export GCC_VERSION=5.2.0; fi
  if [[ "${GCC_VERSION}" == "5.3" ]]; then export GCC_VERSION=5.3.0; fi

  if [[ ${#BOOST_VERSION} -eq 4 ]]; then BOOST_VERSION+=".0"; fi

  echo "Configuration: "
  echo "BOOST_VERSION = " "${BOOST_VERSION}"
  echo "GCC_VERSION = " "${GCC_VERSION}"
  echo "LLVM_VERSION = " "${LLVM_VERSION}"
  echo

  ############################################################################
  # Install Boost headers
  ############################################################################
    if [[ "${BOOST_VERSION}" != "" ]]; then
      export BOOST_DIR=${DEPS_DIR}/boost-${BOOST_VERSION}
      if [[ -z "$(ls -A ${BOOST_DIR})" ]]; then
        if [[ "${BOOST_VERSION}" == "trunk" ]]; then
          echo "Installing boost from trunk"
          BOOST_URL="http://github.com/boostorg/boost.git"
          travis_retry git clone --depth 1 --recursive --quiet ${BOOST_URL} ${BOOST_DIR}
          (cd ${BOOST_DIR} && ./bootstrap.sh && ./b2 headers)
        else
          echo "Installing boost from sourceforge"
          BOOST_URL="http://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION}/boost_${BOOST_VERSION//\./_}.tar.gz"
          mkdir -p ${BOOST_DIR}
          travis_retry wget --quiet -O - ${BOOST_URL} | tar --strip-components=1 -xz -C ${BOOST_DIR}
        fi
      fi
      export BOOST_ROOT="${BOOST_DIR}"
    fi
  ############################################################################
  # Install a recent CMake (unless already installed on OS X)
  ############################################################################
    if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
      if [[ ! -x ${DEPS_DIR}/cmake/bin/cmake ]]; then
        CMAKE_URL="http://www.cmake.org/files/v3.5/cmake-3.5.2-Linux-x86_64.tar.gz"
        mkdir -p ${DEPS_DIR}/cmake
        travis_retry wget --no-check-certificate --quiet -O - ${CMAKE_URL} | tar --strip-components=1 -xz -C cmake
      fi
      if [[ ! -x  ${DEPS_DIR}/cmake/bin/cmake ]]; then echo "WARN: wtf where is cmake"; fi
      export PATH=${DEPS_DIR}/cmake/bin:${PATH}
    else
      if ! brew ls --version cmake &>/dev/null; then brew install cmake; fi
    fi
  ############################################################################
  # Install Boost.Build
  ############################################################################
    if [[ "${BOOST_BUILD}" == "true" ]]; then
      if [[ -x "${DEPS_DIR}/b2/bin/b2" ]]; then
        echo "Found boost build"
      else
        echo "Compiling boost build"
        (cd ${BOOST_DIR}/tools/build && ./bootstrap.sh && ./b2 install --prefix=${DEPS_DIR}/b2) || { echo "Failed to build boost.build"; exit 1; }
      fi
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
        echo "Downloading clang"
        travis_retry wget --quiet -O - ${LLVM_URL}      | tar --strip-components=1 -xJ -C ${LLVM_DIR}
        travis_retry wget --quiet -O - ${LIBCXX_URL}    | tar --strip-components=1 -xJ -C ${LLVM_DIR}/projects/libcxx
        travis_retry wget --quiet -O - ${LIBCXXABI_URL} | tar --strip-components=1 -xJ -C ${LLVM_DIR}/projects/libcxxabi
        travis_retry wget --quiet -O - ${CLANG_URL}     | tar --strip-components=1 -xJ -C ${LLVM_DIR}/clang
        echo "Configuring clang"
        cd ${LLVM_DIR}/build
        cmake .. -DCMAKE_INSTALL_PREFIX=${LLVM_DIR}/install -DCMAKE_CXX_COMPILER=clang++ || exit 1
      fi

      if [[ ! -x "${LLVM_DIR}/clang/bin/clang++" ]]; then
        echo "Resuming compilation of clang"
        cd ${LLVM_DIR}/build/projects/libcxx
        travis_limit_time make install -j2
        cd ${LLVM_DIR}/build/projects/libcxxabi
        travis_limit_time make install -j2
      fi

      if [[ -x "${LLVM_DIR}/clang/bin/clang++" ]]; then
        echo "Found clang"
        export CXXFLAGS="-nostdinc++ -isystem ${LLVM_DIR}/install/include/c++"
        export LDFLAGS="-L ${LLVM_DIR}/install/lib -l c++ -l c++abi"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LLVM_DIR}/install/lib"
        export PATH="${LLVM_DIR}/clang/bin:${PATH}"
      else
        echo "Could not finish compiling clang"
        export COMPILATION_NOT_FINISHED=true
      fi
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
        echo "Downloading gcc"
        travis_retry wget --quiet -O - ${GCC_URL} | tar --strip-components=1 -xz -C ${GCC_SRC_DIR}
        # c.f. https://gcc.gnu.org/wiki/InstallingGCC
        cd ${GCC_SRC_DIR} && travis_retry ./contrib/download_prerequisites
        #disable-bootstrap is an unusual option, but we're trying to make it build in < 60 min
        echo "Configuring gcc"
        cd ${GCC_OBJ_DIR}
        ${GCC_SRC_DIR}/configure --prefix=${GCC_DIR}  --disable-checking --enable-languages=c,c++ --disable-multilib --disable-bootstrap --disable-libsanitizer --disable-libquadmath --disable-libgomp --disable-libssp --disable-libvtv --disable-libada --enable-version-specific-runtime-libs || exit 1
      fi

      if [[ ! -x "${GCC_DIR}/bin/g++" ]]; then
        echo "Proceeding with compilation of g++"
        cd ${GCC_OBJ_DIR}
        travis_limit_time make install -j2
      fi

      if [[ -x "${GCC_DIR}/bin/g++" ]]; then
        echo "Found gcc"
        export CXXFLAGS="-nostdinc++ -isystem ${GCC_DIR}/include/c++"
        export LDFLAGS="-L ${GCC_DIR}/lib -l libstdc++"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GCC_DIR}/lib"
        export PATH="${GCC_DIR}/bin:$PATH"
      else
        echo "Could not finish compiling gcc"
        export COMPILATION_NOT_FINISHED=true
      fi
    fi

  ###
  # Change back to build directory
  ##

  cd ${TRAVIS_BUILD_DIR}
