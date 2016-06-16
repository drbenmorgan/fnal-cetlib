#ifndef cetlib_container_algorithms_h
#define cetlib_container_algorithms_h

// ======================================================================
//
// container_algorithms: Function templates wrapping standard algorithms
//
// Avoids incompatible iterators and reduces some duplication
//
// ======================================================================

#include "cetlib/compiler_macros.h"

#include <algorithm>
#include <iterator>

// ----------------------------------------------------------------------
// C++ 2011 has std::begin() and std::end(), but not the obvious const
// versions.  C++14 does have them, but only gcc 5.1 and above have
// them. In order to avoid client code failures when moving to a
// compiler which supports std::cbegin() and std::cend() properly, one
// should use the following idiom:
//
// {
//   using namespace std;
//   using namespace cet::container_helpers;
//   // Use cbegin(), cend(), without expliict qualification.
// }
namespace cet {
  namespace container_helpers {
#ifdef CET_NO_STD_CBEGIN_CEND
    template <class Container>
    auto cbegin(Container const& c)
    { return c.cbegin(); }

    template <class Container>
    auto cend(Container const& c)
    { return c.cend(); }
#endif
  }

  // Wrappers for std::for_each().
  template <class FwdCont, class Func>
  auto for_all(FwdCont &, Func);
  template <class FwdCont, class Func>
  auto for_all(FwdCont const &, Func);

  // Wrappers for std::copy().
  template <class FwdCont, class FwdIter>
  auto copy_all(FwdCont &, FwdIter);
  template <class FwdCont, class FwdIter>
  auto copy_all(FwdCont const &, FwdIter);

  // Wrappers for std::copy_if().
  template <class FwdCont, class FwdIter, class Pred>
  auto copy_if_all(FwdCont &, FwdIter, Pred);
  template <class FwdCont, class FwdIter, class Pred>
  auto copy_if_all(FwdCont const &, FwdIter, Pred);

  // Wrappers for std::find().
  template <class FwdCont, class Datum>
  auto find_in_all(FwdCont &, Datum const &);
  template <class FwdCont, class Datum>
  auto find_in_all(FwdCont const &, Datum const &);
  template <class FwdCont, class Datum>
  bool search_all(FwdCont const &, Datum const &);

  // Wrapper for std::binary_search().
  template <class FwdCont, class Datum>
  bool binary_search_all(FwdCont const &, Datum const &);

  // Wrappers for std::lower_bound().
  template <class FwdCont, class Datum>
  auto lower_bound_all(FwdCont &, Datum const &);
  template <class FwdCont, class Datum>
  auto lower_bound_all(FwdCont const &, Datum const &);
  template <class FwdCont, class Datum, class Pred>
  auto lower_bound_all(FwdCont &, Datum const &, Pred);
  template <class FwdCont, class Datum, class Pred>
  auto lower_bound_all(FwdCont const &, Datum const &, Pred);

  // Wrappers for std::sort().
  template <class RandCont>
  void sort_all(RandCont &);
  template <class RandCont, class Pred>
  void sort_all(RandCont &, Pred);

  // Wrappers for std::stable_sort().
  template <class RandCont>
  void stable_sort_all(RandCont &);
  template <class RandCont, class Pred>
  void stable_sort_all(RandCont &, Pred);

  // Wrappers for std::transform().
  // One-container input.
  template <class Container, class OutputIt, class UnaryOp>
  auto transform_all(Container &, OutputIt, UnaryOp);
  template <class Container, class OutputIt, class UnaryOp>
  auto transform_all(Container const &, OutputIt, UnaryOp);
  // Two-container input.
  template <class Container1, class Container2, class OutputIt, class BinaryOp>
  auto transform_all(Container1 &, Container2 &, OutputIt, BinaryOp);
  template <class Container1, class Container2, class OutputIt, class BinaryOp>
  auto transform_all(Container1 const &, Container2 const &, OutputIt, BinaryOp);
}

// for_all().
template< class FwdCont, class Func >
inline auto
cet::for_all( FwdCont & s, Func f )
{
  using namespace std;
  using namespace cet::container_helpers;
  return for_each(begin(s), end(s), f);
}

template< class FwdCont, class Func >
inline auto
cet::for_all( FwdCont const & s, Func f )
{
  using namespace std;
  using namespace cet::container_helpers;
  return for_each(cbegin(s), cend(s), f);
}

// copy_all().
template< class FwdCont, class FwdIter >
inline auto
cet::copy_all( FwdCont & s, FwdIter it )
{
  using namespace std;
  using namespace cet::container_helpers;
  return copy(begin(s), end(s), it);
}

template< class FwdCont, class FwdIter >
inline auto
cet::copy_all( FwdCont const & s, FwdIter it )
{
  using namespace std;
  using namespace cet::container_helpers;
  return std::copy(cbegin(s), cend(s), it);
}

// copy_if_all().
template< class FwdCont, class FwdIter, class Pred >
inline auto
cet::copy_if_all( FwdCont & s, FwdIter it, Pred p)
{
  using namespace std;
  using namespace cet::container_helpers;
  return copy_if(begin(s), end(s), it, p );
}

template< class FwdCont, class FwdIter, class Pred >
inline auto
cet::copy_if_all( FwdCont const & s, FwdIter it, Pred p )
{
  using namespace std;
  using namespace cet::container_helpers;
  return copy_if(cbegin(s), cend(s), it, p);
}

// Find_in_all().
template< class FwdCont, class Datum >
inline auto
cet::find_in_all( FwdCont & s, Datum const & d )
{
  using namespace std;
  using namespace cet::container_helpers;
  return find(begin(s), end(s), d);
}

template< class FwdCont, class Datum >
inline auto
cet::find_in_all( FwdCont const & s, Datum const & d )
{
  using namespace std;
  using namespace cet::container_helpers;
  return find(cbegin(s), cend(s), d);
}

// search_all().
template< class FwdCont, class Datum >
inline bool
cet::search_all( FwdCont const & s, Datum const & d )
{
  using namespace std;
  using namespace cet::container_helpers;
  return find(cbegin(s), cend(s), d) != s.end();
}

// binary_search_all().
template< class FwdCont, class Datum >
inline bool
cet::binary_search_all( FwdCont const & s, Datum const & d )
{
  using namespace std;
  using namespace cet::container_helpers;
  return binary_search(cbegin(s), cend(s), d);
}

// lower_bound_all().
template< class FwdCont, class Datum >
inline auto
cet::lower_bound_all( FwdCont & s, Datum const & d )
{
  using namespace std;
  using namespace cet::container_helpers;
  return lower_bound(begin(s), end(s), d);
}

template< class FwdCont, class Datum >
inline auto
cet::lower_bound_all( FwdCont const & s, Datum const & d )
{
  using namespace std;
  using namespace cet::container_helpers;
  return lower_bound(cbegin(s), cend(s), d);
}

template< class FwdCont, class Datum, class Pred >
inline auto
cet::lower_bound_all( FwdCont & s, Datum const & d, Pred p )
{
  using namespace std;
  using namespace cet::container_helpers;
  return lower_bound(begin(s), end(s), d, p);
}

template< class FwdCont, class Datum, class Pred >
inline auto
cet::lower_bound_all( FwdCont const & s, Datum const & d, Pred p )
{
  using namespace std;
  using namespace cet::container_helpers;
  return lower_bound(cbegin(s), cend(s), d, p);
}

// sort_all().
template< class RandCont >
inline void
cet::sort_all( RandCont & s )
{
  using namespace std;
  using namespace cet::container_helpers;
  sort(begin(s), end(s));
}

template< class RandCont, class Pred >
inline void
cet::sort_all( RandCont & s, Pred p )
{
  using namespace std;
  using namespace cet::container_helpers;
  sort(begin(s), end(s), p);
}

// stable_sort_all().
template< class RandCont >
inline void
cet::stable_sort_all( RandCont & s )
{
  using namespace std;
  using namespace cet::container_helpers;
  stable_sort(begin(s), end(s));
}

template< class RandCont, class Pred >
inline void
cet::stable_sort_all( RandCont & s, Pred p )
{
  using namespace std;
  using namespace cet::container_helpers;
  stable_sort(begin(s), end(s), p);
}

// transform_all().
template< class Container, class OutputIt, class UnaryOp >
inline auto
cet::transform_all( Container & in,
                    OutputIt out, UnaryOp unary_op)
{
  using namespace std;
  using namespace cet::container_helpers;
  return transform(begin(in), end(in), out, unary_op);
}

template< class Container, class OutputIt, class UnaryOp >
inline auto
cet::transform_all( Container const& in,
                    OutputIt out, UnaryOp unary_op )
{
  using namespace std;
  using namespace cet::container_helpers;
  return transform(cbegin(in), cend(in), out, unary_op);
}

template< class Container1, class Container2, class OutputIt, class BinaryOp >
inline auto
cet::transform_all( Container1 & in1,
                    Container2 & in2,
                    OutputIt out, BinaryOp binary_op)
{
  using namespace std;
  using namespace cet::container_helpers;
  return transform(begin(in1), end(in1), begin(in2), out, binary_op);
}

template< class Container1, class Container2, class OutputIt, class BinaryOp >
inline auto
cet::transform_all( Container1 const& in1,
                    Container2 const& in2,
                    OutputIt out, BinaryOp binary_op )
{
  using namespace std;
  using namespace cet::container_helpers;
  return transform(cbegin(in1), cend(in1), cbegin(in2), out, binary_op);
}

#endif /* cetlib_container_algorithms_h */

// Local variables:
// mode: c++
// End:
