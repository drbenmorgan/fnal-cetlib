#define BOOST_TEST_MODULE ( map_vector test )

#include "cetlib/quiet_unit_test.hpp"
#include <boost/test/output_test_stream.hpp>
#include "cetlib/map_vector.h"
#include <iostream>
#include <string>

using cet::map_vector;
using cet::map_vector_key;

BOOST_AUTO_TEST_SUITE( map_vector_test )

class cout_redirect
{
public:
  cout_redirect( std::streambuf * new_buf )
    : old_buf( std::cout.rdbuf(new_buf) )
  { }

  ~cout_redirect( )  { std::cout.rdbuf(old_buf); }

private:
  std::streambuf * old_buf;
};

BOOST_AUTO_TEST_CASE( key_test )
{
  {
    boost::test_tools::output_test_stream output;
    {
      cout_redirect guard( output.rdbuf() );
      map_vector_key k(3);
      std::cout << k << std::endl;
    }
    BOOST_CHECK( output.is_equal("3\n") );
  }

  {
    map_vector_key k1(11), k2(12);
    BOOST_CHECK( k1 == k1 );
    BOOST_CHECK( k1 != k2 );
    BOOST_CHECK( k1 <= k2 );
    BOOST_CHECK( k1 <  k2 );
  }

  {
    map_vector_key k1(123u), k2(123uL);
    BOOST_CHECK( k1 == k2 );
  }

}

BOOST_AUTO_TEST_CASE( emptymap_test )
{
  map_vector_key k(3);
  {
    map_vector<int> m;
    BOOST_CHECK( m.empty() );
    BOOST_CHECK( m.size() == 0u );
    BOOST_CHECK( ! m.has(k) );
    BOOST_CHECK( m.begin() == m.end() );
    BOOST_CHECK( m.find(k) == m.end() );
    BOOST_CHECK( m.getOrNull(k) == 0 );
    BOOST_CHECK_THROW( m.getOrThrow(k), cet::exception );
    BOOST_CHECK_THROW( m.front(), cet::exception );
    BOOST_CHECK_THROW( m.back(), cet::exception );
  }

  {
    map_vector<int> const m;
    BOOST_CHECK( m.empty() );
    BOOST_CHECK( m.size() == 0u );
    BOOST_CHECK( ! m.has(k) );
    BOOST_CHECK( m.begin() == m.end() );
    BOOST_CHECK( m.find(k) == m.end() );
    BOOST_CHECK( m.getOrNull(k) == 0 );
    BOOST_CHECK_THROW( m.getOrThrow(k), cet::exception );
    BOOST_CHECK_THROW( m.front(), cet::exception );
    BOOST_CHECK_THROW( m.back(), cet::exception );
  }
}

BOOST_AUTO_TEST_CASE( nonemptymap_test )
{
  typedef  int  value_t;
  map_vector<value_t> m;
  std::size_t sz(0);

  {
    map_vector_key k(1);
    value_t  v(10 + k.asInt());
    m[k] = v;
    BOOST_CHECK( ! m.empty() );
    BOOST_CHECK( m.size() == ++sz );
    BOOST_CHECK( m.begin() != m.end() );
    BOOST_CHECK( m.has(k) );
    BOOST_CHECK( m.find(k)->second == v );
    BOOST_CHECK( *m.getOrNull(k) == v );
    BOOST_CHECK( m.getOrThrow(k) == v );
  }

  {
    map_vector_key k(3);
    value_t  v(10 + k.asInt());
    m[k] = v;
    BOOST_CHECK( ! m.empty() );
    BOOST_CHECK( m.size() == ++sz );
    BOOST_CHECK( m.begin() != m.end() );
    BOOST_CHECK( m.has(k) );
    BOOST_CHECK( m.find(k)->second == v );
    BOOST_CHECK( *m.getOrNull(k) == v );
    BOOST_CHECK( m.getOrThrow(k) == v );
  }

  {
    map_vector_key k(5);
    value_t  v(10 + k.asInt());
    m[k] = v;
    BOOST_CHECK( ! m.empty() );
    BOOST_CHECK( m.size() == ++sz );
    BOOST_CHECK( m.begin() != m.end() );
    BOOST_CHECK( m.has(k) );
    BOOST_CHECK( m.find(k)->second == v );
    BOOST_CHECK( *m.getOrNull(k) == v );
    BOOST_CHECK( m.getOrThrow(k) == v );
  }

  {
    map_vector_key k(2);
    value_t  v(10 + k.asInt());
    m[k] = v;
    BOOST_CHECK( ! m.empty() );
    BOOST_CHECK( m.size() == ++sz );
    BOOST_CHECK( m.begin() != m.end() );
    BOOST_CHECK( m.has(k) );
    BOOST_CHECK( m.find(k)->second == v );
    BOOST_CHECK( *m.getOrNull(k) == v );
    BOOST_CHECK( m.getOrThrow(k) == v );
  }

  {
    map_vector<value_t> m2(m);
    BOOST_CHECK( m2.size() == sz );

    m2.insert(m.begin(), m.end());
    BOOST_CHECK( m2.size() == 2 * sz );
    map_vector<value_t>::const_iterator b = m.begin();
    for ( const auto& entry : m2 ) {
      if( b == m.end() )
        b = m.begin();
      BOOST_CHECK( b->second == entry.second );
      ++b;
    }
    int d = m.delta();
    for( map_vector<value_t>::const_iterator b1 = m2.begin()
                                           , b2 = b1 + sz
                                           , e  = m2.end();  b2 != e;  ++b1, ++b2 )  {
      BOOST_CHECK_EQUAL( b1->first.asInt() + d, b2->first.asInt() );
    }

  }

}

BOOST_AUTO_TEST_SUITE_END()
