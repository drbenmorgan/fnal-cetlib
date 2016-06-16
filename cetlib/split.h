#ifndef cetlib_split_h
#define cetlib_split_h

// ======================================================================
//
// split: Obtain substrings at a string's specified boundaries.
//
// Examples of splitting with ':' as the separator:
//    input     result
//     ""       [ ]                # Different behavior than split_by_regex.h
//     "a"      ["a"]
//     "a:"     ["a"]
//     ":boo"   ["boo"]            # Different behavior than split_by_regex.h
//     "a:b"    ["a","b"]
//     "a::b"   ["a","b"] // N.B.! # Different behavior than split_by_regex.h
//
// ======================================================================

#include <algorithm>
#include <functional>
#include <string>

namespace cet  {
  template< class OutIter >
  void
  split( std::string const & s, char c, OutIter dest );

  template< class Pred, class OutIter >
  void
  split_if( std::string const & s, Pred is_sep, OutIter dest );
}

// ======================================================================

template< class OutIter >
void
cet::split( std::string const & s, char c, OutIter dest )
{
  using std::placeholders::_1;

  std::equal_to<char> eq;
  split_if( s, std::bind(eq,_1,c), dest );
}

// ======================================================================

namespace cet { namespace detail {

    template< class F >
    class negate
    {
    public:
      negate( F f ) : f(f)  { }
      bool  operator () ( char c ) const  { return ! f(c); }
    private:
      F f;
    };  // negate

  } }  // cet::detail


template< class Pred, class OutIter >
void
cet::split_if( std::string const & s, Pred is_sep, OutIter dest )
{
  typedef  std::string::const_iterator  str_c_iter;
  str_c_iter  b = s.begin()
    ,  e = s.end();

  detail::negate<Pred> is_not_sep(is_sep);

  // invariant:  we've found all items in [b..boi)
  for( str_c_iter  boi = std::find_if(b, e, is_not_sep)
         ,  eoi = e  // arbitrary initializer
         ; boi != e;  boi = std::find_if(eoi, e, is_not_sep)
       )
    {
      // find end of current item:
      eoi = std::find_if(boi, e, is_sep);

      // copy the item formed from characters in [boi..eoi):
      *dest++ = std::string(boi, eoi);
    }  // for

}  // split_if<>()

// ======================================================================

#endif /* cetlib_split_h */

// Local variables:
// mode:c++
// End:
