#include "cetlib/PluginFactory.h"

#include "cetlib/detail/wrapLibraryManagerException.h"
#include "cetlib_except/exception.h"

#include <string>

cet::PluginFactory::
PluginFactory(std::string const& suffix) :
  lm_{suffix}
{}

std::string
cet::PluginFactory::
releaseVersion_() const
{
  std::string result;
  if (releaseVersionFunc_) {
    result = releaseVersionFunc_();
  } else {
    result = releaseVersionString_.empty() ?
             "Unknown" :
             releaseVersionString_;
  }
  return result;
}
