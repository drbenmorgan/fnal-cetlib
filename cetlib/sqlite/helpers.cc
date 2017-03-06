// =======================================================
//
// sqlite helpers
//
// =======================================================

#include <cassert>
#include <cmath>
#include <regex>

#include "cetlib/sqlite/Exception.h"
#include "cetlib/sqlite/helpers.h"

namespace {
  std::string normalize(std::string to_replace)
  {
    // Replace multiple spaces with 1 space.
    {
      std::regex const r {"\\s+"};
      to_replace = std::regex_replace(to_replace, r, " ");
    }
    // Ensure no spaces after commas
    {
      std::regex const r {", "};
      to_replace = std::regex_replace(to_replace, r, ",");
    }
    return to_replace;
  }
}

//=================================================================
// hasTableWithSchema(db, name, cnames) returns true if the db has
// a table named 'name', with columns named 'cns' suitable for
// carrying a tuple<ARGS...>. It returns false if there is no
// table of that name, and throws an exception if there is a table
// of the given name but it does not match both the given column
// names and column types.
bool
cet::sqlite::hasTableWithSchema(sqlite3* db, std::string const& name, std::string const& expectedSchema)
{
  std::string cmd {"select sql from sqlite_master where type=\"table\" and name=\""};
  cmd += name;
  cmd += '"';

  auto const res = query<std::string>(db, cmd);

  if (res.empty())
    return false;

  if (res.data.size() != 1ull) {
    throw sqlite::Exception(sqlite::errors::SQLExecutionError)
      << "Problematic query: " << res.data.size() << " instead of 1.\n";
  }

  // This is a somewhat fragile way of validating schemas.  A
  // better way would be to rely on sqlite3's insertion facilities
  // to determine if an insert of in-memory data would be
  // compatible with the on-disk schema.  This would require
  // creating a temporary table (so as to avoid inserting then
  // deleting a dummy row into the desired table)according to the
  // on-disk schema, and inserting some default values according
  // to the requested schema.
  std::string retrievedSchema;
  std::tie(retrievedSchema) = res.data[0];
  if (normalize(retrievedSchema) == normalize(expectedSchema))
    return true;

  throw sqlite::Exception(sqlite::errors::SQLExecutionError)
    << "Existing database table name does not match description:\n"
    << "   DDL on disk: " << normalize(retrievedSchema) << '\n'
    << "   Current DDL: " << normalize(expectedSchema) << '\n';
}

namespace cet {
  namespace sqlite {
    namespace detail {

      //================================================================
      // The locking mechanisms for nfs systems are deficient and can
      // thus wreak havoc with sqlite, which depends upon them.  In
      // order to support an sqlite database on nfs, we use a URI,
      // explicitly including the query parameter: 'nolock=1'.  We will
      // have to revisit this choice once we consider multiple
      // processes/threads writing to the same database file.
      inline std::string assembleURI(std::string const& filename)
      {
        // Arbitrary decision: don't allow users to specify a URI since
        // they may (unintentionally) remove the 'nolock' parameter,
        // thus potentially causing issues with nfs.
        if (filename.substr(0,5) == "file:") {
          throw sqlite::Exception{sqlite::errors::OtherError}
          << "art does not allow an SQLite database filename that starts with 'file:'.\n"
               << "Please contact artists@fnal.gov if you believe this is an error.";
        }
        return "file:"+filename+"?nolock=1";
      }

    } // detail
  } // sqlite
} // cet

sqlite3*
cet::sqlite::openDatabaseFile(std::string const& filename)
{
  sqlite3* db {nullptr};
  std::string const uri = detail::assembleURI(filename);
  int const rc = sqlite3_open_v2(uri.c_str(),
                                 &db,
                                 SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_URI,
                                 nullptr);
  if (rc != SQLITE_OK) {
    sqlite3_close(db);
    throw sqlite::Exception{sqlite::errors::SQLExecutionError}
    << "Failed to open SQLite database\n"
         << "Return code: " << rc;
  }

  assert(db);
  return db;
}

//=======================================================================
void
cet::sqlite::deleteTable(sqlite3* db, std::string const& tname)
{
  exec(db, "delete from "s + tname);
}

void
cet::sqlite::dropTable(sqlite3* db, std::string const& tname)
{
  exec(db, "drop table "s+ tname);
}

unsigned
cet::sqlite::nrows(sqlite3* db, std::string const& tname)
{
  auto r = query<unsigned>(db,"select count(*) from "+tname+";");
  return unique_value(r);
}