#define BOOST_TEST_MODULE ( zero_init test )
#include "cetlib/quiet_unit_test.hpp"

#include "cetlib/zero_init.h"

using cet::zero_init;

BOOST_AUTO_TEST_SUITE( zero_init_tests )

BOOST_AUTO_TEST_CASE( default_behavior ) {
  { typedef  int  T;
    BOOST_CHECK_EQUAL( zero_init<T>() ,0 );
    zero_init<T> x;
    BOOST_CHECK_EQUAL( x, 0 );
    BOOST_CHECK_EQUAL( sizeof(x), sizeof(T) );
    T & r = x;
    BOOST_CHECK_EQUAL( r, 0 );
  }
  { typedef  unsigned long  T;
    BOOST_CHECK_EQUAL( zero_init<T>(), 0u );
    zero_init<T> x;
    BOOST_CHECK_EQUAL( x, 0u );
    BOOST_CHECK_EQUAL( sizeof(x), sizeof(T) );
    T & r = x;
    BOOST_CHECK_EQUAL( r, 0u );
  }
}

BOOST_AUTO_TEST_CASE( copy_behavior ) {
  { typedef  unsigned  T;
    zero_init<T> x;
    zero_init<T> y = x;
    BOOST_CHECK_EQUAL( x, y );
    BOOST_CHECK_EQUAL( y, x );
    BOOST_CHECK_EQUAL( (y = x), x );
    BOOST_CHECK_EQUAL( (x = y), y );
    BOOST_CHECK_EQUAL( (x = 2.5), T(2) );
    BOOST_CHECK_EQUAL( (x = zero_init<double>(2.5)), T(2) );
  }
  { typedef  long  T;
    zero_init<T> x = 7L;
    BOOST_CHECK_EQUAL( x, T(7) );
    zero_init<T> y(x);
    BOOST_CHECK_EQUAL( y, T(7) );
    BOOST_CHECK_EQUAL( y, x );
    BOOST_CHECK_EQUAL( (x = 2.5), T(2.5) );
    BOOST_CHECK_EQUAL( (x = zero_init<double>(2.5)), T(2.5) );
  }
}

BOOST_AUTO_TEST_CASE( const_behavior ) {
  { typedef  int const  T;
    zero_init<T> x;
    T y = x;
    BOOST_CHECK_EQUAL( x, y );
    BOOST_CHECK_EQUAL( y, x );
    T & r = x;
    BOOST_CHECK_EQUAL( r, y );
  }
  { typedef  int  T;
    zero_init<T> const x;
    T const y = x;
    BOOST_CHECK_EQUAL( x, y );
    BOOST_CHECK_EQUAL( y, x );
    T const & r = x;
    BOOST_CHECK_EQUAL( r, y );
  } }

BOOST_AUTO_TEST_CASE( conversions ) {
  {
    zero_init<long> x = zero_init<int >(16);
    zero_init<int > y = zero_init<long>(16L) + 0L;
    BOOST_CHECK_EQUAL( x, y );
    BOOST_CHECK_EQUAL( y, x + 0 );
  }
  {
    zero_init<float> z;
    BOOST_CHECK_EQUAL( z, 0.0F );
  }
}

BOOST_AUTO_TEST_SUITE_END()
