// ======================================================================
//
// filepath_maker: A family of related policies governing the translation
//                 of a filename into a fully-qualified filepath
//
// ======================================================================

#include "cetlib/filepath_maker.h"
#include "cetlib/filesystem.h"

using cet::filepath_maker;
using cet::filepath_lookup;
using cet::filepath_lookup_nonabsolute;
using cet::filepath_lookup_after1;

// ----------------------------------------------------------------------

std::string
  filepath_maker::operator () ( std::string const & filename )
{ return filename; }

// ----------------------------------------------------------------------

filepath_lookup::filepath_lookup( std::string paths )
  : filepath_maker( )
  , paths         ( paths )
{ }

std::string
  filepath_lookup::operator () ( std::string const & filename )
{
  return paths.find_file(filename);
}

// ----------------------------------------------------------------------

filepath_lookup_nonabsolute::filepath_lookup_nonabsolute( std::string paths )
  : filepath_maker( )
  , paths         ( paths )
{ }

std::string
  filepath_lookup_nonabsolute::operator () ( std::string const & filename )
{
  return cet::is_absolute_filepath(filename) ? filename
                                             : paths.find_file(filename);
}

// ----------------------------------------------------------------------

filepath_lookup_after1::filepath_lookup_after1( std::string paths )
  : filepath_maker( )
  , after1        ( false )
  , paths         ( paths )
{ }

std::string
  filepath_lookup_after1::operator () ( std::string const & filename )
{
  return after1 ? paths.find_file(filename)
                : (after1 = true, filename);
}

void
  filepath_lookup_after1::reset( )
{ after1 = false; }

// ======================================================================
