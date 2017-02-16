#ifndef cetlib_Ntuple_sqlite_result_h
#define cetlib_Ntuple_sqlite_result_h

// =======================================================
//
// sqlite result
//
// =======================================================

#include <vector>

#include "cetlib/Ntuple/sqlite_stringstream.h"
#include "cetlib/Ntuple/Exception.h"
#include "cetlib/container_algorithms.h"

namespace sqlite {

  struct result {
    std::vector<std::string> columns;
    std::vector<sqlite::stringstream> data;
    bool empty() const { return data.empty(); }

    auto begin() { return data.begin(); }
    auto end() { return data.end(); }

    explicit operator bool() const { return empty(); }

    template <typename T>
    result& operator>>(T& t) {
      if (!data.empty())
        data[0] >> t;
      return *this;
    }

    template <typename T>
    result& operator>>(std::vector<T>& vt)
    {
      vt.clear();
      cet::transform_all(data,
                         std::back_inserter(vt),
                         [](auto& ss){ T t; ss>>t; return t; });
      return *this;
    }

  };

  inline result& throw_if_empty(result& r)
  {
    if (r.empty())
      throw sqlite::Exception{sqlite::errors::SQLExecutionError} << "SQL query failed.";
    return r;
  }

  std::ostream& operator<<(std::ostream&, result const&);

} //namespace sqlite

#endif /* cetlib_Ntuple_sqlite_result_h */

// Local Variables:
// mode: c++
// End:
