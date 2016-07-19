#include <iostream>
#include <boost/version.hpp>

int main() {
  std::cout << "GCC Ver = " << __GNUC__ << "." << __GNUC_MINOR__ << "." << __GNUC_PATCHLEVEL__ << std::endl;
  std::cout << "__VERSION__ = " << __VERSION__ << std::endl;
  std::cout << std::endl;
#ifdef __clang__
    std::cout << "__clang__ = " << 1 << std::endl;
    std::cout << "Clang Ver = " << __clang_major__ << "." << __clang_minor__ << "." << __clang_patchlevel__ << std::endl;
    std::cout << "__clang_version__ = " << __clang_version__ << std::endl;
#else // __clang__
    std::cout << "__clang__ = " << 0 << std::endl;
#endif // __clang__
  std::cout << std::endl;
#ifdef BOOST_LIB_VERSION
  std::cout << "BOOST_LIB_VERSION = " << BOOST_LIB_VERSION << std::endl;
#else
  std::cout << "BOOST_LIB_VERSION = ???" << std::endl;
#endif
}
