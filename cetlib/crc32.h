#ifndef cetlib_crc32_h
#define cetlib_crc32_h

// ======================================================================
//
// crc32: Calculate a CRC32 checksum
//
// ======================================================================

#include <cstdint>
#include <string>

namespace cet {
  class crc32;
}

// ======================================================================

class cet::crc32 {
public:
  using uchar = unsigned char;
  using digest_t = std::uint32_t;

  constexpr crc32() = default;
  explicit crc32(std::string const& mesg);
  explicit crc32(char const mesg);

  crc32& operator<<(std::string const& mesg);
  crc32& operator<<(char const mesg);

  digest_t digest();

private:
  digest_t context {0xFFFFFFFFL};

};  // crc32

// ======================================================================

#endif /* cetlib_crc32_h */

// Local Variables:
// mode: c++
// End:
