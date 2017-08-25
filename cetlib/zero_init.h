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
  template <typename T,
            typename = std::enable_if_t<std::is_arithmetic<T>::value || std::is_pointer<T>::value>>
  class zero_init;
}

// ----------------------------------------------------------------------

template <typename T, typename>
class cet::zero_init {
  using T_ref = std::add_lvalue_reference_t<T>;

public:

  zero_init() = default;
  zero_init(T const val) : val{val} {}

  template <typename OT,
            typename = std::enable_if_t<std::is_convertible<OT,T>::value>>
  zero_init(zero_init<OT> const& other)
    : val{static_cast<T>(other)}
  {}

  template <typename OT,
            typename = std::enable_if_t<std::is_convertible<OT,T>::value>>
  zero_init& operator=(zero_init<OT> const& other)
  {
    val = static_cast<T>(other);
    return *this;
  }

  operator T_ref    ()       { return val; }
  operator T const& () const { return val; }

private:
  T val{};

};  // zero_init<T>

// ======================================================================

#endif /* cetlib_zero_init_h */

// Local Variables:
// mode: c++
// End:
