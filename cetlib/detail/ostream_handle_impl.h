#ifndef cetlib_detail_ostream_handle_impl_h
#define cetlib_detail_ostream_handle_impl_h

#include <fstream>
#include <ostream>
#include <string>

namespace cet {
  namespace detail {

    // Interface
    class ostream_handle_base {
    public:
      virtual ~ostream_handle_base() = default;
      std::ostream& stream() { return get_stream(); }
    private:
      virtual std::ostream& get_stream() = 0;
    };

    // Concrete types below
    class ostream_observer : public ostream_handle_base {
    public:
      ostream_observer(std::ostream& os) : os_{os} {}
    private:
      std::ostream& os_;
      std::ostream& get_stream() override { return os_; }
    };

    class ostream_owner : public ostream_handle_base {
    public:
      ostream_owner(std::string const& fn,
                    std::ios_base::openmode const mode = std::ios_base::out) : ofs_{fn, mode} {}
      ~ostream_owner() override { ofs_.close(); }
    private:
      std::ofstream ofs_;
      std::ostream& get_stream() override { return ofs_; }
    };
  }

}

#endif /* cetlib_detail_ostream_handle_impl_h */

// Local variables:
// mode: c++
// End:
