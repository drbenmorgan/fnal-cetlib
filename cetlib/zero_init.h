#ifndef cetlib_zero_init_h
#define cetlib_zero_init_h

// ======================================================================
//
// zero_init: Wrap a value of native arithmetic or pointer type T,
//            ensuring a default-initialized value of T(0)
//
// ======================================================================

#include <type_traits>

namespace cet {
  template< class T
          , class = typename std::enable_if<  std::is_arithmetic<T>::value
                                           || std::is_pointer   <T>::value
                                           >::type
          >
    class zero_init;
}

// ----------------------------------------------------------------------

template< class T, class >
  class cet::zero_init
{
  typedef  typename std::conditional< std::is_const<T>::value
                                    , T
                                    , T &
                                    >::type
           T_ref;

public:
  zero_init( )       : val( static_cast<T>(0) )  { }
  zero_init( T val ) : val( val               )  { }

  // use compiler-generated copy c'tor, copy assignment, and d'tor

#if defined __GXX_EXPERIMENTAL_CXX0X__  || ( defined __cplusplus && __cplusplus >= 201103L )
  template< class OT
          , class = typename std::enable_if< std::is_convertible<OT,T>::value
                                           >::type
          >
    zero_init( zero_init<OT> const & other )
#else
  template< class OT >
    zero_init( zero_init<OT> const & other
             , typename std::enable_if< std::is_convertible<OT,T>::value
                                      >::type * = 0
             )
#endif
  : val( static_cast<T>(other) )
  { }

#if defined __GXX_EXPERIMENTAL_CXX0X__
  template< class OT
          , class = typename std::enable_if< std::is_convertible<OT,T>::value
                                           >::type
          >
  zero_init &
#else
  template< class OT >
  typename std::enable_if< std::is_convertible<OT,T>::value
                         , zero_init &
                         >::type
#endif
    operator = ( zero_init<OT> const & other )
  {
    val = static_cast<T>(other);
    return *this;
  }

  operator T_ref     ( )        { return val; }
  operator T const & ( ) const  { return val; }

private:
  T val;

};  // zero_init<T>

// ======================================================================

#endif /* cetlib_zero_init_h */

// Local Variables:
// mode: c++
// End:
