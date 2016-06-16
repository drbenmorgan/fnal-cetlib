#ifndef cetlib_ostream_handle_h
#define cetlib_ostream_handle_h

/*
   ====================================================================

   ostream_handle

   This is a handle for dealing with owning/non-owning ostream
   objects.  There are use cases when one needs an externally provided
   stream (i.e. std::cout or std::cerr), and cases when one needs an
   owned stream (std::ofstream).  This handle enables a consistent use
   of both.

   Base class:     cet::ostream_handle (abstract)

   Concrete types: cet::ostream_owner
                   cet::ostream_observer

   Example use:

     std::unique_ptr<cet::ostream_handle> osh;
     if ( owned ) osh = std::make_unique<cet::ostream_owner>("filename.txt");
     else         osh = std::make_unique<cet::ostream_observer>(std::cout);

     // stream to output
     *osh << 4 << "thirteen";
     osh.stream() << 5 << "fourteen";

   ====================================================================
*/

#include <fstream>
#include <ostream>
#include <string>

namespace cet {

  // Interface

  class ostream_handle {
  public:

    virtual ~ostream_handle() = default;

    template <typename T>
    ostream_handle& operator<<(T const& t)
    {
      get_stream() << t;
      return *this;
    }

    std::ostream& stream() { return get_stream(); }

  private:

    virtual std::ostream& get_stream() = 0;

  };

  // Concrete types below

  class ostream_observer : public ostream_handle {
  public:

    ostream_observer(std::ostream& os) : os_{os} {}

  private:

    std::ostream& os_;
    std::ostream& get_stream() override { return os_; }

  };

  class ostream_owner : public ostream_handle {
  public:

    ostream_owner(std::string const& fn,
                  std::ios_base::openmode const mode = std::ios_base::out) : ofs_{fn, mode} {}
    ~ostream_owner() override { ofs_.close(); }

  private:

    std::ofstream ofs_;
    std::ostream& get_stream() override { return ofs_; }

  };

}

#endif /* cetlib_ostream_handle_h */

// Local variables:
// mode: c++
// End:
