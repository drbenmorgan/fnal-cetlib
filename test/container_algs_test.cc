#define BOOST_TEST_MODULE ( container_algorithms test )
#include "boost/test/auto_unit_test.hpp"
#include "boost/test/test_tools.hpp"
#include "cetlib/container_algorithms.h"
#include <map>
#include <utility>

namespace {

  //using cet::cbegin;
  //using cet::cend;

  template <class T>
  struct A {
    A(T t) : t_(t) {}
    T t_;

    bool operator<(A<T> const& r) const
    {
      return t_ < r.t_;
    }

    bool operator==(A<T> const& r) const
    {
      return t_ == r.t_;
    }

    bool operator!=(A<T> const& r) const
    {
      return !operator==(r);
    }
  };

  template<class T>
  std::ostream& operator<<(std::ostream& os, A<T> const& a)
  {
    return os << a.t_;
  }

  template <class T>
  struct MakeA {
    auto operator()(T const val) const { return A<T>{val}; }
  };

  template <class T, class U>
  struct MakeAPair {
    auto operator()(T const t, U const u) const { return std::pair<T,U>{t,u}; }
  };

}

BOOST_AUTO_TEST_SUITE( container_algorithms )

BOOST_AUTO_TEST_CASE( copy_all ) {

  std::vector<int> a { 1, 2, 3, 4 };
  std::vector<int> b;
  cet::copy_all(a, std::back_inserter(b));

}

BOOST_AUTO_TEST_CASE( transform_all ) {

  std::vector<int>  const v1 { 1, 2, 3, 4 };
  std::vector<char> const v2 { 'a', 'b', 'c', 'd' };

  // One-input version
  std::vector<A<int>> is1, is2;
  std::vector<A<char>> cs1, cs2;
  std::map<A<int>,A<char>> p1, p2;

  std::transform( cet::cbegin(v1), cet::cend(v1), std::back_inserter(is1), MakeA<int>() );
  std::transform( cet::cbegin(v2), cet::cend(v2), std::back_inserter(cs1), MakeA<char>() );
  std::transform( cet::cbegin(v1), cet::cend(v1), cet::cbegin(v2), std::inserter(p1, begin(p1)), MakeAPair<int,char>() );

  cet::transform_all( v1, std::back_inserter(is2), MakeA<int>() );
  cet::transform_all( v2, std::back_inserter(cs2), MakeA<char>() );
  cet::transform_all( v1, v2, std::inserter(p2, begin(p2)), MakeAPair<int,char>() );

  BOOST_CHECK_EQUAL_COLLECTIONS( cet::cbegin(is1), cet::cend(is1), cet::cbegin(is2), cet::cend(is2) );
  BOOST_CHECK_EQUAL_COLLECTIONS( cet::cbegin(cs1), cet::cend(cs1), cet::cbegin(cs2), cet::cend(cs2) );

  BOOST_CHECK_EQUAL( p1.size(), p2.size() );

  auto p1_it = cet::cbegin(p1);
  auto p2_it = cet::cbegin(p1);
  for ( ; p1_it != cet::cend(p1) ; ++p1_it, ++p2_it ) {
    BOOST_CHECK_EQUAL( p1_it->first.t_ , p2_it->first.t_ );
    BOOST_CHECK_EQUAL( p1_it->second.t_, p2_it->second.t_ );
  }

}
BOOST_AUTO_TEST_SUITE_END()
