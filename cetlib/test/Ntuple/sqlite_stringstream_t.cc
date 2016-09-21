#include "cetlib/Ntuple/sqlite_stringstream.h"
#include "cetlib/Ntuple/Exception.h"

#include <string>

using namespace std::string_literals;
using namespace sqlite;

int main() {

  stringstream ss;

  // put a few things in
  ss << "const char*"
     << "std::string"s
     << 1
     << 2.4
     << 3.6f;

  std::string first;
  std::string second;
  int one;
  double next;
  float last;

  if ( !ss.empty() ) {
    ss >> first
       >> second
       >> one
       >> next
       >> last;
  }

  try {
    int x;
    ss >> x;
    throw sqlite::Exception( sqlite::errors::Unknown,"shouldn't get here");
  }
  catch ( sqlite::Exception const & e ) {
    if ( e.categoryCode() == sqlite::errors::Unknown ) {
      throw sqlite::Exception( sqlite::errors::Unknown, "this is really bad" );
    }
  }
  catch (...){}

}
