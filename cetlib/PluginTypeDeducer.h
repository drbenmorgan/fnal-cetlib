#ifndef cetlib_PluginTypeDeducer_h
#define cetlib_PluginTypeDeducer_h

////////////////////////////////////////////////////////////////////////
// PluginTypeDeducer
//
// An aid to managing multiple plugin types. See
// cetlib/BasicPluginFactory.h for background.
//
// Specialize this class for your own plugin type and make sure it is
// seen before being required. A reasonable place would be the in the
// header file of the plugin type's base class (assuming there is one),
// immediately below the forward declaration of the base class name.
//
// Define a macro DEFINE_BASIC_PLUGINTYPE_FUNC(base) to produce a
// pluginType() function for a plugin library which should be findable
// by BasicPluginFactory::pluginType(const std::string & libspec).
//
// PluginTypeDeducer<> is used rather than a sinple string literal to
// allow for the ability for users of the plugin factory to compare the
// answer with a known value to verify the type of the plugin found.
////////////////////////////////////////////////////////////////////////

#include <string>

namespace cet {
  // PluginTypeDeducer.
  template <typename T>
    struct PluginTypeDeducer;
}

#define DEFINE_BASIC_PLUGINTYPE_FUNC_DETAIL(base) \
  extern "C" {                                    \
    std::string                                   \
    pluginType()                                  \
    {                                             \
      return cet::PluginTypeDeducer<base>::value; \
    }                                             \
  }

#ifdef __clang__
#define DEFINE_BASIC_PLUGINTYPE_FUNC(base)                         \
  _Pragma("clang diagnostic push")                                 \
  _Pragma("clang diagnostic ignored \"-Wreturn-type-c-linkage\"")  \
  DEFINE_BASIC_PLUGINTYPE_FUNC_DETAIL(base)                        \
  _Pragma("clang diagnostic pop")
#else
#define DEFINE_BASIC_PLUGINTYPE_FUNC DEFINE_BASIC_PLUGINTYPE_FUNC_DETAIL
#endif

template <typename T>
struct cet::PluginTypeDeducer {
  static std::string const value;
};

template <typename T>
std::string const
cet::PluginTypeDeducer<T>::
value = "Unknown";

#endif /* cetlib_PluginTypeDeducer_h */

// Local Variables:
// mode: c++
// End:
