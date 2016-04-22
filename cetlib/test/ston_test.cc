#define BOOST_TEST_MODULE ( ston test )
#include "cetlib/quiet_unit_test.hpp"

#include "cetlib/ston.h"

#include <string>
#include <stdexcept>

using cet::ston;
using std::string;
using std::invalid_argument;

BOOST_AUTO_TEST_SUITE( ston_test )

BOOST_AUTO_TEST_CASE( signed_test )
{
  BOOST_CHECK_EQUAL( ston<int      >("1"), 1   );
  BOOST_CHECK_EQUAL( ston<long     >("2"), 2L  );
  BOOST_CHECK_EQUAL( ston<long long>("3"), 3LL );

  BOOST_CHECK_THROW( ston<int      >("1X"), invalid_argument );
  BOOST_CHECK_THROW( ston<long     >("Y2"), invalid_argument );
  BOOST_CHECK_THROW( ston<long long>("3."), invalid_argument );
}

BOOST_AUTO_TEST_CASE( unsigned_test )
{
  BOOST_CHECK_EQUAL( ston<unsigned int      >("11"), 11U   );
  BOOST_CHECK_EQUAL( ston<unsigned long     >("12"), 12UL  );
  BOOST_CHECK_EQUAL( ston<unsigned long long>("13"), 13ULL );

  BOOST_CHECK_THROW( ston<unsigned int      >("11X"), invalid_argument );
  BOOST_CHECK_THROW( ston<unsigned long     >("1Y2"), invalid_argument );
  BOOST_CHECK_THROW( ston<unsigned long long>("13."), invalid_argument );
}

BOOST_AUTO_TEST_CASE( floating_test )
{
  BOOST_CHECK_EQUAL( ston<float      >("21."), 21.F );
  BOOST_CHECK_EQUAL( ston<double     >("22."), 22.  );
  BOOST_CHECK_EQUAL( ston<long double>("23."), 23.L );

  BOOST_CHECK_THROW( ston<float      >("21.X"), invalid_argument );
  BOOST_CHECK_THROW( ston<double     >("2Y." ), invalid_argument );
  BOOST_CHECK_THROW( ston<long double>("Z3." ), invalid_argument );
}

BOOST_AUTO_TEST_SUITE_END()
