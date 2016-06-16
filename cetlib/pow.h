#ifndef cetlib_pow_h
#define cetlib_pow_h

// ======================================================================
//
// pow<>(): Minimal-multiply algorithm for integral non-negative powers
//
// ======================================================================

#include "cetlib/exception.h"

#include <type_traits>

namespace cet {

  template< unsigned N, class T >  inline T  pow( T x );

  template< class T >  inline T  square( T x )  { return pow<2u>(x); }
  template< class T >  inline T  cube  ( T x )  { return pow<3u>(x); }
  template< class T >  inline T  fourth( T x )  { return pow<4u>(x); }

  template< class T >  inline T  diff_of_squares( T x, T y );
  template< class T >  inline T  sum_of_squares ( T x, T y );
  template< class T >  inline T  sum_of_squares ( T x, T y, T z );
}

namespace cet { namespace detail {

  template< unsigned N, class T, unsigned = N % 2u >
    struct pow;

  template< unsigned N, class T >  struct pow<N,T,0u>;
  template< unsigned N, class T >  struct pow<N,T,1u>;

  template< class T >  struct pow<0u,T,0u>;
  template< class T >  struct pow<1u,T,1u>;
  template< class T >  struct pow<2u,T,0u>;

} }  // cet::detail

// ----------------------------------------------------------------------

template< unsigned N, class T >
inline T
  cet::pow( T x )
{ return detail::pow<N,T>()( x ); }

// ----------------------------------------------------------------------

template< unsigned N, class T >
  struct cet::detail::pow<N,T,0u>
{
  pow<N/2u,T> pow_half;
  T
    operator () ( T x )
  { return pow_half(x * x); }
};  // pow<N,T,0>

template< unsigned N, class T >
  struct cet::detail::pow<N,T,1u>
{
  pow<N/2u,T> pow_half;
  T
    operator () ( T x )
  { return x * pow_half(x * x); }
};  // pow<N,T,1>

template< class T >
  struct cet::detail::pow<0u,T,0u>
{
  T  operator () ( T x )
  {
    if( x == 0 )
      throw cet::exception("cet::pow" ) << "pow<0>(0) is indeterminate!";
    return 1;
  }
};  // pow<0,T,0>

template< class T >
  struct cet::detail::pow<1u,T,1u>
{
  T  operator () ( T x ) { return x; }
};  // pow<1,T,1>

template< class T >
  struct cet::detail::pow<2u,T,0u>
{
  T  operator () ( T x ) { return x * x; }
};  // pow<2,T,0>

// ----------------------------------------------------------------------

template< class T >
inline T
  cet::diff_of_squares( T x, T y )
{ return (x+y) * (x-y); }

template< class T >
inline T
  cet::sum_of_squares( T x, T y )
{ return square(x) + square(y); }

template< class T >
inline T
  cet::sum_of_squares( T x, T y, T z )
{ return square(x) + square(y) + square(z); }

// ======================================================================

#endif /* cetlib_pow_h */

// Local Variables:
// mode: c++
// End:
