#ifndef CETLIB_CONTAINER_ALGORITHMS_H
#define CETLIB_CONTAINER_ALGORITHMS_H

// ======================================================================
//
// container_algorithms: Function templates wrapping standard algorithms
//
// Avoids incompatible iterators and reduces some duplication
//
// ======================================================================

#include <algorithm>
#include <iterator>

// ----------------------------------------------------------------------
// C++ 2011 has std::begin() and std::end(), but not the obvious const
// versions.  C++14 does have them, but only gcc 5.1 and above have
// them.
namespace cet {
  template <class Container>
  auto cbegin(Container const& c)
  { return c.cbegin(); }

  template <class Container>
  auto cend(Container const& c)
  { return c.cend(); }
}

// ----------------------------------------------------------------------
// wrappers for std::for_each
namespace cet {
  template< class FwdCont, class Func >
  inline auto
  for_all( FwdCont & s, Func f )
  { return std::for_each(std::begin(s), std::end(s), f); }

  template< class FwdCont, class Func >
  inline auto
  for_all( FwdCont const & s, Func f )
  { return std::for_each(cbegin(s), cend(s), f); }
}

// ----------------------------------------------------------------------
// wrappers for std::copy
namespace cet {
  template< class FwdCont, class FwdIter >
  inline auto
  copy_all( FwdCont & s, FwdIter it )
  { return std::copy(std::begin(s), std::end(s), it); }

  template< class FwdCont, class FwdIter >
  inline auto
  copy_all( FwdCont const & s, FwdIter it )
  { return std::copy(cbegin(s), cend(s), it); }
}

// ----------------------------------------------------------------------
// wrappers for std::copy_if
namespace cet {
  template< class FwdCont, class FwdIter, class Pred >
  inline auto
  copy_if_all( FwdCont & s, FwdIter it, Pred p)
  { return std::copy_if(std::begin(s), std::end(s), it, p ); }

  template< class FwdCont, class FwdIter, class Pred >
  inline auto
  copy_if_all( FwdCont const & s, FwdIter it, Pred p )
  { return std::copy_if(cbegin(s), cend(s), it, p); }
}

// ----------------------------------------------------------------------
// wrappers for std::find
namespace cet {
  template< class FwdCont, class Datum >
  inline auto
  find_in_all( FwdCont & s, Datum const & d )
  { return std::find(std::begin(s), std::end(s), d); }

  template< class FwdCont, class Datum >
  inline auto
  find_in_all( FwdCont const & s, Datum const & d )
  { return std::find(cbegin(s), cend(s), d); }

  template< class FwdCont, class Datum >
  inline bool
  search_all( FwdCont const & s, Datum const & d )
  { return std::find(cbegin(s), cend(s), d) != s.end(); }
}

// ----------------------------------------------------------------------
// wrapper for std::binary_search
namespace cet {
  template< class FwdCont, class Datum >
  inline bool
  binary_search_all( FwdCont const & s, Datum const & d )
  { return std::binary_search(cbegin(s), cend(s), d); }
}

// ----------------------------------------------------------------------
// wrappers for std::lower_bound
namespace cet {
  template< class FwdCont, class Datum >
  inline auto
  lower_bound_all( FwdCont const & s, Datum const & d )
  { return std::lower_bound(cbegin(s), cend(s), d); }

  template< class FwdCont, class Datum >
  inline auto
  lower_bound_all( FwdCont & s, Datum const & d )
  { return std::lower_bound(std::begin(s), std::end(s), d); }

  template< class FwdCont, class Datum, class Pred >
  inline auto
  lower_bound_all( FwdCont & s, Datum const & d, Pred p )
  { return std::lower_bound(std::begin(s), std::end(s), d, p); }

  template< class FwdCont, class Datum, class Pred >
  inline auto
  lower_bound_all( FwdCont const & s, Datum const & d, Pred p )
  { return std::lower_bound(cbegin(s), cend(s), d, p); }
}

// ----------------------------------------------------------------------
// wrappers for std::sort
namespace cet {
  template< class RandCont >
  inline void
  sort_all( RandCont & s )
  { std::sort(std::begin(s), std::end(s)); }

  template< class RandCont, class Pred >
  inline void
  sort_all( RandCont & s, Pred p )
  { std::sort(std::begin(s), std::end(s), p); }
}

// ----------------------------------------------------------------------
// wrappers for std::stable_sort
namespace cet {
  template< class RandCont >
  inline void
  stable_sort_all( RandCont & s )
  { std::stable_sort(std::begin(s), std::end(s)); }

  template< class RandCont, class Pred >
  inline void
  stable_sort_all( RandCont & s, Pred p )
  { std::stable_sort(std::begin(s), std::end(s), p); }
}

// ----------------------------------------------------------------------
// wrappers for std::transform
namespace cet {

  // One-container input
  template< class Container, class OutputIt, class UnaryOp >
  inline auto
  transform_all( Container & in,
                 OutputIt out, UnaryOp unary_op)
  { return std::transform(std::begin(in), std::end(in), out, unary_op); }

  template< class Container, class OutputIt, class UnaryOp >
  inline auto
  transform_all( Container const& in,
                 OutputIt out, UnaryOp unary_op )
  { return std::transform(cet::cbegin(in), cet::cend(in), out, unary_op); }

  // Two-container input
  template< class Container1, class Container2, class OutputIt, class BinaryOp >
  inline auto
  transform_all( Container1 & in1,
                 Container2 & in2,
                 OutputIt out, BinaryOp binary_op)
  { return std::transform(std::begin(in1), std::end(in1), std::begin(in2), out, binary_op); }

  template< class Container1, class Container2, class OutputIt, class BinaryOp >
  inline auto
  transform_all( Container1 const& in1,
                 Container2 const& in2,
                 OutputIt out, BinaryOp binary_op )
  { return std::transform(cet::cbegin(in1), cet::cend(in1), cet::cbegin(in2), out, binary_op); }
}

// ======================================================================

#endif

// Local variables:
// mode: c++
// End:
