#include <algorithm>
#include <regex>

namespace cet {

  std::vector<std::string> split_by_regex (std::string const& str,
                                           std::string const& delimSet )
  {
    std::vector<std::string> tokens;
    auto tmp = std::regex(delimSet);
    std::copy( std::sregex_token_iterator(str.begin(),
                                          str.end(),
                                          tmp,
                                          -1),
               std::sregex_token_iterator(),
               std::back_inserter( tokens ) );
    return tokens;
  }

}

