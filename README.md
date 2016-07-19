travis-ci c++ assistant
=======================

Have a travis-ci C++ project?

This assistant can be used to set up a nice, modern C++ build environment with
multiple versions of boost, gcc, and clang, with relative ease.

To use the assistant, set up your `.travis.yml` as follows

* Configure your *build matrix* to set the variables `COMPILER`, `BOOST_VERSION`,
  and variously `LLVM_VERSION` or (eventually) `GCC_VERSION`
* Configure your *cache* to cache the `~/deps` directory, which is where the assitant
  installs things.
* During the *install* step, clone *this repository* and run `./install.sh`.

You may examine the `.travis.yml` of this repo to see examples.

For more info about caching, and clearing a bad cache, see travis-ci docs.
