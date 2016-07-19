#include <algorithm>
#include <sstream>
#include <iostream>
#include <string>
#include <boost/version.hpp>

std::string ver_string(int a, int b, int c) {
  std::ostringstream ss;
  ss << a << '.' << b << '.' << c;
  return ss.str();
}

void normalize_boost_ver(std::string & ver) {
  std::replace(ver.begin(), ver.end(), '_', '.');

  if (std::count(ver.begin(), ver.end(), '.') < 2) {
    ver += ".0";
  }

}

int test(const char * name, std::string val, std::string true_val) {
  if (val == true_val) {
    std::cout << "   " << name << " = " << val << std::endl;
    return 0;
  } else {
    std::cerr << " ! " << name << " = " << val << " , but in fact was compiled with " << true_val << std::endl;
    return 1;
  }
}

int main(int argc, char ** argv) {

  std::string true_cxx =
#ifdef __clang__
   "clang++";
#else
   "g++";
#endif

  std::string true_cxx_ver =
#ifdef __clang__
  ver_string(__clang_major__, __clang_minor__, __clang_patchlevel__);
#else
  ver_string(__GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
#endif

  std::string true_boost = BOOST_LIB_VERSION;
  normalize_boost_ver(true_boost);

  if (argc < 4) { std::cout << "Expected to be passed: ${CXX} ${CXX_VERSION} ${BOOST_VERSION}\n" << std::endl; return 1; }

  std::string cxx = argv[1];
  std::string cxx_ver = argv[2];
  std::string boost_ver = argv[3];

  normalize_boost_ver(boost_ver);

  int result = 0;

  std::cout << "Compiler and Boost versions:\n" << std::endl;

#define EXPECT(var, val)  \
  result += test(#var, var, val);

  EXPECT(cxx, true_cxx);
  EXPECT(cxx_ver, true_cxx_ver);
  EXPECT(boost_ver, true_boost);

  std::cout << std::endl;

  std::cout << (result ? "FAIL" : "OK") << "\n" << std::endl;

  return result;
}
