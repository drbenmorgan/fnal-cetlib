#define BOOST_TEST_MODULE ( ntos test )
#include "cetlib/quiet_unit_test.hpp"

#include "cetlib/ntos.h"

#include <string>

using cet::ntos;
using std::string;

BOOST_AUTO_TEST_SUITE( ntos_test )

BOOST_AUTO_TEST_CASE( signed_test )
{
  BOOST_CHECK_EQUAL( ntos(1  ), string("1") );
  BOOST_CHECK_EQUAL( ntos(2L ), string("2") );
  BOOST_CHECK_EQUAL( ntos(3LL), string("3") );
}

BOOST_AUTO_TEST_CASE( unsigned_test )
{
  BOOST_CHECK_EQUAL( ntos(11U  ), string("11") );
  BOOST_CHECK_EQUAL( ntos(12UL ), string("12") );
  BOOST_CHECK_EQUAL( ntos(13ULL), string("13") );
}

BOOST_AUTO_TEST_CASE( floating_test )
{
  BOOST_CHECK_EQUAL( ntos(21.F), string("21.000000") );
  BOOST_CHECK_EQUAL( ntos(22. ), string("22.000000") );
  BOOST_CHECK_EQUAL( ntos(23.L), string("23.000000") );
}

BOOST_AUTO_TEST_SUITE_END()
