// ======================================================================
//
// getenv - obtain value of environment variable; throw if none such
//
// ======================================================================

#include "cetlib/getenv.h"

#include "cetlib/exception.h"
#include <cstdlib>

// ======================================================================

std::string
  cet::getenv( std::string const & name )
{
  char const * p = std::getenv(name.c_str());
  if( p == 0 )
    throw cet::exception("getenv")
      << "Can't find an environment variable named \"" << name << '\"';
  return p;
}

// ======================================================================
