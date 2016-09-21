#include "cetlib/Ntuple/Exception.h"

using namespace sqlite;

// Map an sqlite::errors::ErrorCodes into the appropriate string.
std::string
ExceptionDetail::translate(errors::ErrorCodes const code)
{
  using namespace errors;

  switch(code) {
  case LogicError        : return "LogicError";
  case SQLExecutionError : return "SQLExecutionError";
  case OtherError        : return "OtherError";
  case Unknown           : return "Unknown";
  }
  throw Exception(errors::LogicError)
    << "Internal error: missing string translation for error "
    << code
    << " which was not caught at compile time!\n";
}

// ======================================================================
