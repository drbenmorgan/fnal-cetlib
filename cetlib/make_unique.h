#ifndef cetlib_make_unique_h
#define cetlib_make_unique_h

#include <memory>
#include <utility>

#define DEPRECATION_MESSAGE                                     \
  "\n\n"                                                        \
  "cetlib warning: 'cet::make_unique' has been deprecated.\n"   \
  "                Use 'std::make_unique' instead.\n\n"

namespace cet
{
  template <class T, class ... Args>
  [[deprecated(DEPRECATION_MESSAGE)]]
  auto make_unique(Args&& ... args) {
    return std::make_unique<T>(std::forward<Args>(args)...);
  }
}

#endif /* cetlib_make_unique_h */

// Local variables:
// mode: c++
// End:
