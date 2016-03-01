#define BOOST_TEST_MODULE ( demangle test )
#include "cetlib/quiet_unit_test.hpp"

#include "cetlib/demangle.h"

#include <iostream>

BOOST_AUTO_TEST_SUITE ( DemangleTests )

BOOST_AUTO_TEST_CASE ( type )
{
  BOOST_REQUIRE_EQUAL(cet::demangle_symbol("t"), "unsigned short");
}

BOOST_AUTO_TEST_CASE ( vtable )
{
  BOOST_REQUIRE_EQUAL(cet::demangle_symbol("_ZTVN3cet9exceptionE"),
                      "vtable for cet::exception");
}

BOOST_AUTO_TEST_CASE ( message )
{
  BOOST_REQUIRE_EQUAL(cet::demangle_message("Unable to resolve symbol: _ZTVN3cet9exceptionE"),
                      "Unable to resolve symbol: vtable for cet::exception");
}

BOOST_AUTO_TEST_CASE ( function )
{
  BOOST_REQUIRE_EQUAL(cet::demangle_symbol("_ZN3cet8demangleERKSs"),
                      "cet::demangle(std::string const&)");
}

BOOST_AUTO_TEST_CASE ( fail )
{
  BOOST_REQUIRE_EQUAL(cet::demangle_symbol("_ZN13Xrawfileparser13RawFileParserD1Ev"),
                      "_ZN13Xrawfileparser13RawFileParserD1Ev");
}

BOOST_AUTO_TEST_SUITE_END()
