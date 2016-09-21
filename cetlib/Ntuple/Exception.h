#ifndef cetlib_Ntuple_Exception_h
#define cetlib_Ntuple_Exception_h

// ======================================================================
//
// Exception: sqlite-specific customizations for cetlib/coded_exception
//
// ======================================================================

#include "cetlib/coded_exception.h"
#include <string>

// ----------------------------------------------------------------------

namespace sqlite {
  namespace errors {

    enum ErrorCodes {
      LogicError = 0,
      SQLExecutionError,
      OtherError,
      Unknown
    };

  }  // errors

  namespace ExceptionDetail {
    std::string translate(errors::ErrorCodes);
  }

  using Exception = cet::coded_exception<errors::ErrorCodes, ExceptionDetail::translate>;

}  // art

// ======================================================================

#endif /* canvas_Utilities_Exception_h */

// Local Variables:
// mode: c++
// End:
