travis-ci c++ assistant
=======================

The purpose of this project is to provide scripts which can be used in a modern
C++ project and get compilers / boost versions installed.

To use the assistant, set up your `.travis.yml` as follows

* Configure your *build matrix* to set the variables `COMPILER`, `BOOST_VERSION`,
  and variously `LLVM_VERSION` or (eventually) `GCC_VERSION`
* Configure your *cache* to cache the `~/deps` directory, which is where the assitant
  installs things.
* During the *install* step, clone this repository and run `./install.sh`.

You may examine the `.travis.yml` of this repo to see examples.

For more info about caching, and clearing a bad cache, see travis-ci docs.
