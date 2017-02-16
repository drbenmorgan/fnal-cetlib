#define BOOST_TEST_MODULE (simultaneous_function_spawner test)
#include "cetlib/quiet_unit_test.hpp"
#include "cetlib/SimultaneousFunctionSpawner.h"
#include <iostream>

BOOST_AUTO_TEST_SUITE(simultaneous_function_spawner)

BOOST_AUTO_TEST_CASE(cout)
{
  auto task = []{std::cout << "Hello concurrent world.\n";};
  cet::SimultaneousFunctionSpawner<7u> sfs {task};
}

BOOST_AUTO_TEST_CASE(non_atomic_int)
{
  int i {};
  auto task = [&i]{++i;};
  cet::SimultaneousFunctionSpawner<7u> sfs {task};
  std::cout << i << '\n'; // Don't expect it to necessarily be 7
}

BOOST_AUTO_TEST_CASE(atomic_int)
{
  std::atomic<int> i {1};
  auto task = [&i]{++i;};
  cet::SimultaneousFunctionSpawner<7u> sfs {task};
  BOOST_REQUIRE_EQUAL(i, 8);
}

BOOST_AUTO_TEST_SUITE_END()
