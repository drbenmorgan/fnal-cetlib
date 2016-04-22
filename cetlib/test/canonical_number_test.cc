#include "cetlib/canonical_number.h"
#include <cstdlib>
#include <iostream>
#include <string>


using cet::canonical_number;


void
  ensure( int which, bool claim )
{
  if( not claim )
    std::exit(which);
}

bool
  becomes( std::string const & input
         , std::string const & wanted
         )
{
  std::string result;
  if( ! canonical_number(input, result) )
    return false;

  if( result == wanted )
    return true;

  std::cerr << "Input:  " << input  << '\n'
            << "Wanted: " << wanted << '\n'
            << "Result: " << result << '\n'
            ;
  return false;
}


int
  main( )
{
  ensure( 1, becomes(  "0", "0" ) );
  ensure( 2, becomes( "+0", "0" ) );
  ensure( 3, becomes( "-0", "0" ) );
  ensure( 4, becomes(  "000", "0" ) );
  ensure( 5, becomes( "+000", "0" ) );
  ensure( 6, becomes( "-000", "0" ) );
  ensure( 7, becomes(  "0.0", "0" ) );
  ensure( 8, becomes( "+0.0", "0" ) );
  ensure( 9, becomes( "-0.0e-5", "0" ) );

  ensure( 11,   becomes(  "123456", "123456" ) );
  ensure( 12,   becomes( "12345678", "1.2345678e7" ) );
  ensure( 13, ! becomes( "", "" ) );
  ensure( 14,   becomes(  ".12", "1.2e-1" ) );
  ensure( 15,   becomes( "12E4", "120000" ) );
  ensure( 16,   becomes( "12E5", "1.2e6" ) );
  ensure( 17,   becomes( "12.000E5", "1.2e6" ) );
  ensure( 18,   becomes( "12E-4", "1.2e-3" ) );
  ensure( 19,   becomes( "0.09", "9e-2" ) );

  ensure( 21,   becomes( "-0.0e-0", "0" ) );
  ensure( 22,   becomes( "+0.0E0", "0" ) );
  ensure( 22,   becomes( "-0e99", "0" ) );
  ensure( 23,   becomes( "-.00", "0" ) );

  ensure( 31, ! becomes( "1.2.3", "" ) );
  ensure( 32, ! becomes( "1.2,3", "" ) );
  ensure( 33, ! becomes( "1.2X3", "" ) );
  ensure( 34, ! becomes( "0x123abx", "" ) );
  ensure( 35, ! becomes( "+0x123ab", "" ) );
  ensure( 36, ! becomes( "0x", "" ) );
  ensure( 37, ! becomes( "0b123", "" ) );
  ensure( 38, ! becomes( "+0b101", "" ) );
  ensure( 39, ! becomes( "0b", "" ) );

  ensure( 41,   becomes( "0X000", "0" ) );
  ensure( 42,   becomes( "0x123ab", "74667" ) );
  ensure( 43,   becomes( "0x123DE", "74718" ) );
  ensure( 44,   becomes( "0X123ab", "74667" ) );
  ensure( 45,   becomes( "0X00123De", "74718" ) );
  ensure( 46,   becomes( "0x1234567890", "7.818749352e10" ) );

  ensure( 51,   becomes( "0b000", "0" ) );
  ensure( 51,   becomes( "0b101", "5" ) );
  ensure( 51,   becomes( "0b01101", "13" ) );
  ensure( 51,   becomes( "0b1000110100101100011001", "2.312985e6" ) );

  return 0;

}  // main()
