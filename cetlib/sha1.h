#ifndef CETLIB_SHA1_H
#define CETLIB_SHA1_H

// ======================================================================
//
// sha1: Secure Hash Algorithm as defined in FIPS PUB 180-1, 1993-05-11
//
// ======================================================================

#include "polarssl/sha1.h"
#include <array>
#include <cstring>
#include <string>

namespace cet {
  class sha1;
}

// ======================================================================

class cet::sha1
{
public:
  static  std::size_t const             digest_sz  = 20;
  typedef  unsigned char                uchar;
  typedef  std::array<uchar,digest_sz>  digest_t;

  sha1( ) { reset(); }
  explicit
    sha1( std::string const & mesg ) { reset(); operator<<(mesg); }
  explicit
    sha1( char const mesg ) { reset(); operator<<(mesg); }

  void  reset( ) { polarssl::sha1_starts( & context ); }

  sha1 &
    operator << ( std::string const & mesg )
  {
    polarssl::sha1_update( & context
                         , (uchar const *)( & mesg[0] )
                         , mesg.size()
                         );
    return *this;
  }

  sha1 &
    operator << ( char const mesg )
  {
    polarssl::sha1_update( & context
                         , (uchar const *)( & mesg )
                         , 1u
                         );
    return *this;
  }

  digest_t
    digest( )
  {
    digest_t result;
    polarssl::sha1_finish( & context, & result[0] );
    std::memset( & context, 0, sizeof(polarssl::sha1_context) );
    return result;
  }

private:
  polarssl::sha1_context  context;

};  // sha1

// ======================================================================

#endif
