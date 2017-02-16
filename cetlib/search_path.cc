// ======================================================================
//
// search_path: Seek filename or pattern in a given list of pathnames
//
// ======================================================================

#include "cetlib/search_path.h"

#include "cetlib_except/exception.h"
#include "cetlib/filesystem.h"
#include "cetlib/getenv.h"

#include <dirent.h>
#include <iterator>
#include <ostream>
#include <regex>
#include <sys/stat.h>

using cet::search_path;
using namespace std;

string exception_category("search_path");

// ----------------------------------------------------------------------
// c'tors:

search_path::search_path(string const& arg) : _dirs() {
  if (!arg.empty())
    split(arg.find(':') == string::npos
              ? cet::getenv(arg)  // arg is an env var
              : arg               // arg is a path
          ,
          ':', back_inserter(_dirs));

  if (_dirs.empty()) _dirs.push_back(string());
}  // c'tor


bool search_path::empty() const {
  return _dirs.empty();
}


size_t search_path::size() const {
  return _dirs.size();
}

string const& search_path::operator[](size_t k) const {
  return _dirs.at(k);
}

// ----------------------------------------------------------------------
// find_file() overloads:

string search_path::find_file(string const& filename) const {
  string result;
  if (find_file(filename, result)) return result;
  throw cet::exception(exception_category) << "Can't find file \""
                                           << filename
                                           << '"';
}  // find_file()

bool search_path::find_file(string const& filename,
                            string& result) const {
  if (filename.empty()) return false;

  for (auto const& dir : _dirs) {
    string fullpath = dir + '/' + filename;
    for (size_t k; (k = fullpath.find("//")) != string::npos;) {
      fullpath.erase(k, 1);
    }
    if (cet::file_exists(fullpath)) {
      result = fullpath;
      return true;
    }
  }
  return false;
}  // find_file()

// ----------------------------------------------------------------------

size_t search_path::find_files(string const& pat,
                               vector<string>& out) const {
  regex const re{pat};

  size_t count = 0u;
  size_t err = 0u;
  struct dirent entry;
  struct dirent* result = nullptr;

  for (auto const& dir : _dirs) {
    unique_ptr<DIR, function<int(DIR*)>> dd( opendir(dir.c_str()), closedir);
    if (dd == nullptr) continue;
    while (!(err = readdir_r(dd.get(), &entry, &result)) && result != nullptr) {
      if (regex_match(entry.d_name, re)) {
        out.push_back(dir + '/' + entry.d_name);
        ++count;
      }
    }
    if (result != nullptr)
      throw cet::exception(exception_category)
          << "Failed to read directory \"" << dir << "\"; error num = " << err;
  }  // for

  return count;
}  // find_files()


std::string search_path::to_string() const {
  std::ostringstream oss;
  oss << *this;
  return oss.str();
}

// ======================================================================


namespace cet {

  ostream&
  operator<<(ostream& os, search_path const& path) {
    auto sz = path.size();
    if (sz == 0) return os;
    os << path[0];
    for (size_t k = 1; k != sz; ++k) {
      os << ":" << path[k];
    }
    return os;  
  }

}
