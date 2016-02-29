#ifndef CETLIB_BIT_MANIPULATION_H
#define CETLIB_BIT_MANIPULATION_H

// ======================================================================
//
// bit_manipulation: Compile-time bit manipulations
//
// ======================================================================

#include <cstddef>
#include <limits>
#include <type_traits>

// ======================================================================

namespace cet {

  template< class U
          , bool = std::is_unsigned<U>::value
          >
    struct bit_size;

  template< class U >
    struct bit_size<U,true>
  {
    static  std::size_t const  value = std::numeric_limits<U>::digits;
  };

}  // namespace cet

// ======================================================================

namespace cet {

  template< class U, std::size_t n
          , bool = n < bit_size<U>::value
          >
    struct bit_number;

  template< class U, std::size_t n >
    struct bit_number<U,n,true>
  {
    static  std::size_t const  value = U(1u) << n;
  };

  template< class U, std::size_t n >
    struct bit_number<U,n,false>
  {
    static  std::size_t const  value = U(0u);
  };

}  // namespace cet

// ======================================================================

namespace cet {

  template< class U, std::size_t n
          , bool = std::is_unsigned<U>::value
          , bool = n+1 < bit_size<U>::value
          >
    struct right_bits;

  template< class U, std::size_t n >
    struct right_bits<U,n,true,true>
  {
    static U const value = bit_number<U,n+1>::value - U(1u);
  };

  template< class U, std::size_t n >
    struct right_bits<U,n,true,false>
  {
    static U const value = ~0u;
  };

}  // namespace cet

// ======================================================================

namespace cet {

  template< class U, std::size_t n
          , bool = std::is_unsigned<U>::value
          , bool = n <= bit_size<U>::value
          >
    struct left_bits;

  template< class U, std::size_t n >
    struct left_bits<U,n,true,true>
  {
  private:
    static U const n_zeros = bit_size<U>::value - n;

  public:
    static U const value = ~ right_bits<U,n_zeros>::value;
  };

  template< class U, std::size_t n >
    struct left_bits<U,n,true,false>
  {
    static U const value = U(-1);
  };

}  // namespace cet

// ======================================================================

namespace cet {

  template< class U >
    inline
    typename std::enable_if< std::is_unsigned<U>::value
                           , U
                           >::type
    circ_lshift( U X, U n )
  {
    static  std::size_t const  nbits = bit_size<U>::value;
    static  std::size_t const  mask = nbits - 1;
    n %= nbits;
    return  (X << n)
         |  (X >> (nbits-n)&mask);
  }

}  // namespace cet

// ======================================================================

#endif
