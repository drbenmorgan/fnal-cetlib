#ifndef cetlib_ntos_h
#define cetlib_ntos_h

// ======================================================================
//
// ntos: produce string from number
//
// ======================================================================

#include "boost/lexical_cast.hpp"

#include <string>
#include <type_traits>

// ======================================================================

namespace cet {
  template< class T >
  typename std::enable_if<    std::is_integral<T>::value
                           && (sizeof(T) > sizeof(long long))
                         , std::string
                         >::type
    ntos( T );

  std::string  ntos( int       );
  std::string  ntos( long      );
  std::string  ntos( long long );

  std::string  ntos( unsigned int       );
  std::string  ntos( unsigned long      );
  std::string  ntos( unsigned long long );

  std::string  ntos( float       );
  std::string  ntos( double      );
  std::string  ntos( long double );
}

// ======================================================================

template< class T >
inline typename std::enable_if<    std::is_integral<T>::value
                                && (sizeof(T) > sizeof(long long))
                              , std::string
                              >::type
  cet::ntos( T n )
{ return boost::lexical_cast<std::string>(n); }

// ----------------------------------------------------------------------

inline std::string
  cet::ntos( int       n ) { return std::to_string(n); }
inline std::string
  cet::ntos( long      n ) { return std::to_string(n); }
inline std::string
  cet::ntos( long long n ) { return std::to_string(n); }

// ----------------------------------------------------------------------

inline std::string
  cet::ntos( unsigned int       n ) { return std::to_string(n); }
inline std::string
  cet::ntos( unsigned long      n ) { return std::to_string(n); }
inline std::string
  cet::ntos( unsigned long long n ) { return std::to_string(n); }

// ----------------------------------------------------------------------

inline std::string
  cet::ntos( float       n ) { return std::to_string(n); }
inline std::string
  cet::ntos( double      n ) { return std::to_string(n); }
inline std::string
  cet::ntos( long double n ) { return std::to_string(n); }

// ======================================================================

#endif /* cetlib_ntos_h */

// Local Variables:
// mode: c++
// End:
