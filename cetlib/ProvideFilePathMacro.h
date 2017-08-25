#ifndef cetlib_ProvideFilePathMacro_h
#define cetlib_ProvideFilePathMacro_h

// =====================================================================
//
// HelperMacros
//
// =====================================================================

#include "boost/filesystem.hpp"
#include <string>

namespace bfs = boost::filesystem;

#define CET_PROVIDE_FILE_PATH()                          \
  extern "C"                                             \
  std::string get_source_location()                      \
  {                                                      \
    bfs::path const p {__FILE__};                        \
    return bfs::complete(p).native();                    \
  }

#endif /* cetlib_ProvideFilePathMacro_h */

// Local Variables:
// mode: c++
// End:
