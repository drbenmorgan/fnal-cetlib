#ifndef cetlib_ston_h
#define cetlib_ston_h

// ======================================================================
//
// ston: produce number from string
//
// ======================================================================

#include "boost/lexical_cast.hpp"

#include <limits>
#include <stdexcept>
#include <string>
#include <type_traits>

// ======================================================================

namespace cet {

  template< class T > T ston( std::string );

  template<>  int        ston<int      >( std::string );
  template<>  long       ston<long     >( std::string );
  template<>  long long  ston<long long>( std::string );

  template<>  unsigned int        ston<unsigned int      >( std::string );
  template<>  unsigned long       ston<unsigned long     >( std::string );
  template<>  unsigned long long  ston<unsigned long long>( std::string );

  template<>  float        ston<float      >( std::string );
  template<>  double       ston<double     >( std::string );
  template<>  long double  ston<long double>( std::string );

  template< class T >
  typename std::enable_if<    std::is_integral<T>::value
                           && (sizeof(T) > sizeof(long long))
                         , T
                         >::type
    ston( std::string );
}

// ======================================================================

// ----------------------------------------------------------------------

template<>
int
  cet::ston<int>( std::string s )
{
  std::size_t size;
  int result = stod(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<int>");
  return result;
}

template<>
long
  cet::ston<long>( std::string s )
{
  std::size_t size;
  long result = stol(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<long>");
  return result;
}

template<>
long long
  cet::ston<long long>( std::string s )
{
  std::size_t size;
  long long result = stoll(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<long long>");
  return result;
}

// ----------------------------------------------------------------------

template<>
unsigned
  cet::ston<unsigned>( std::string s )
{
  std::size_t size;
  unsigned long result = stoul(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<unsigned long>");
  if(    result < std::numeric_limits<unsigned>::min()
      || std::numeric_limits<unsigned>::max() < result
    )
    throw std::out_of_range("ston<unsigned long>");
  return static_cast<unsigned>(result);
}

template<>
unsigned long
  cet::ston<unsigned long>( std::string s )
{
  std::size_t size;
  unsigned long result = stoul(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<unsigned long>");
  return result;
}

template<>
unsigned long long
  cet::ston<unsigned long long>( std::string s )
{
  std::size_t size;
  unsigned long long result = stoull(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<unsigned long long>");
  return result;
}

// ----------------------------------------------------------------------

template<>
float
  cet::ston<float>( std::string s )
{
  std::size_t size;
  float result = stof(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<float>");
  return result;
}

template<>
double
  cet::ston<double>( std::string s )
{
  std::size_t size;
  double result = stod(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<double>");
  return result;
}

template<>
long double
  cet::ston<long double>( std::string s )
{
  std::size_t size;
  long double result = stold(s, &size);
  if( size < s.size() )
    throw std::invalid_argument("ston<long double>");
  return result;
}

// ----------------------------------------------------------------------

template< class T >
typename std::enable_if<    std::is_integral<T>::value
                         && (sizeof(T) > sizeof(long long))
                       , T
                       >::type
  cet::ston( std::string s )
try
{
  return boost::lexical_cast<T>(s);
}
catch( boost::bad_lexical_cast )
{
  throw std::invalid_argument("ston<large>");
}

// ======================================================================

#endif /* cetlib_ston_h */

// Local Variables:
// mode: c++
// End:
