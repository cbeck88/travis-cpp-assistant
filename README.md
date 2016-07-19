# travis-ci c++ assistant

[![Build Status](https://travis-ci.org/cbeck88/travis-cpp-assistant.svg?branch=master)](http://travis-ci.org/cbeck88/travis-cpp-assistant)
[![WTFPL licensed](https://img.shields.io/badge/license-WTFPL-blue.svg)](./LICENSE)

Have a travis-ci C++ project?

This assistant can be used to set up a nice, modern C++ build environment with
multiple versions of boost, gcc, and clang, using the correct standard libraries,
with relative ease.

To use the assistant, set up your `.travis.yml` as follows

* Configure your *build matrix* to set the variables `BOOST_VERSION`,
  and variously `LLVM_VERSION` or `GCC_VERSION`, corresponding to `compiler:` setting.

  Version strings should all have two dots, e.g. `GCC_VERSION=4.9.3`, `BOOST_VERSION=1.58.0`.

  ```
  matrix:
    include:
      - os: linux
        env: GCC_VERSION=5.3.0 BOOST_VERSION=1.58.0
        compiler: gcc

      - os: linux
        env: LLVM_VERSION=3.6.2 BOOST_VERSION=1.55.0
        compiler: clang
  ```

* Configure your *cache* to cache the `~/deps` directory.

  ```
  cache:
    directories:
      - ${TRAVIS_BUILD_DIR}/deps
  ```

* During the *install* step, clone this repository and run `source ./install.sh`.
  Actually, it is simplest just to `wget` that shell file:

  ```
  install:
    wget https://raw.githubusercontent.com/cbeck88/travis-cpp-assistant/master/install.sh
    chmod +x install.sh
    source ./install.sh
  ```

  Or, commit it to your repository.

* During your *script* step, use the environment variable `CXX` with your build system,
  and include `BOOST_ROOT` to get the boost headers of the corresponding version.

  You should respect the `CXXFLAGS` and `LDFLAGS` which are exported also.

  ```
  ${CXX} -I${BOOST_ROOT} ${CXXFLAGS} main.cpp -o a.out ${LDFLAGS}
  ```

  If you need to compile boost, then you should `cd` into `BOOST_ROOT` and do it.

* Both `gcc` and `clang` require you to apt-get a few small dependencies into ubuntu-precise.
  `gcc` has some external libs that it needs like `mpfr`. `clang`
  requires a gcc standard library version `>= 4.7`.

  Check out the [.travis.yml](./travis.yml) of this repo to see a full example.

For more info about caching, and clearing a bad cache, see [travis-ci docs](https://docs.travis-ci.com/user/caching/).

Credits
-------

Note that much of this script is derived from the `.travis.yml` file of the [boost::hana](https://github.com/boostorg/hana),
so credit for all the good parts should go to Louis Dionne, and any bugs and problems
were likely my doing.
