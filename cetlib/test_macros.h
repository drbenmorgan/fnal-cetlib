#ifndef cetlib_test_macros_h
#define cetlib_test_macros_h

#include "boost/test/test_tools.hpp"

#define CET_CHECK_EQUAL_COLLECTIONS( test, ref )              \
  BOOST_CHECK_EQUAL_COLLECTIONS( test.begin(), test.end(),    \
                                 ref.begin(), ref.end() )

#endif

