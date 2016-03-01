#define BOOST_TEST_MODULE ( hypot test )
#include "cetlib/quiet_unit_test.hpp"
#include "boost/test/floating_point_comparison.hpp"
#include <cmath>
#include <limits>

#include "cetlib/hypot.h"

using cet::hypot;

BOOST_AUTO_TEST_SUITE( hypot_test )

BOOST_AUTO_TEST_CASE( basic_test ) {
  BOOST_CHECK_EQUAL( hypot(5, 12), 13 );
  BOOST_CHECK_CLOSE( hypot(.5, 1.2), 1.3, 0.0001 );
  BOOST_CHECK_CLOSE( hypot(.05L, .12L), .13L, 0.0001L );
}

BOOST_AUTO_TEST_CASE( nan_test ) {
  BOOST_CHECK( std::isnan( hypot( std::numeric_limits<double>::quiet_NaN()
                                , 1.2
             )           )      );
  BOOST_CHECK( std::isnan( hypot( 3.1415926
                                , std::numeric_limits<double>::quiet_NaN()
             )           )      );
}

BOOST_AUTO_TEST_CASE( inf_test ) {
  BOOST_CHECK( std::isinf( hypot( std::numeric_limits<double>::infinity()
                                , 1.2
             )           )      );
  BOOST_CHECK( std::isinf( hypot( 3.1415926
                                , std::numeric_limits<double>::infinity()
             )           )      );

  BOOST_CHECK( std::isinf( hypot( -std::numeric_limits<double>::infinity()
                                , 1.2
             )           )      );
  BOOST_CHECK( std::isinf( hypot( 3.1415926
                                , -std::numeric_limits<double>::infinity()
             )           )      );
}

BOOST_AUTO_TEST_SUITE_END()
