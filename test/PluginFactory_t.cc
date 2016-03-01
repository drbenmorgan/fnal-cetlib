#define BOOST_TEST_MODULE ( PluginFactory_t )
#include "cetlib/quiet_unit_test.hpp"

#include "cetlib/BasicPluginFactory.h"
#include "cetlib/PluginTypeDeducer.h"
#include "cetlib/exception.h"

#include "TestPluginBase.h"

#include <memory>
#include <string>

using namespace cet;

struct PluginFactoryTestFixture {
  PluginFactoryTestFixture() : pf() { pf.setDiagReleaseVersion("ETERNAL"); }
  ~PluginFactoryTestFixture() = default;

  BasicPluginFactory pf;

};

BOOST_FIXTURE_TEST_SUITE(PluginFactory_t, PluginFactoryTestFixture)

BOOST_AUTO_TEST_CASE(checkType)
{
  BOOST_REQUIRE_EQUAL(std::string("TestPluginBase"), \
                      PluginTypeDeducer<cettest::TestPluginBase>::value);
  BOOST_REQUIRE_EQUAL(pf.pluginType("TestPlugin"), \
                      PluginTypeDeducer<cettest::TestPluginBase>::value);
}

BOOST_AUTO_TEST_CASE(checkMaker)
{
  auto p = pf.makePlugin<std::unique_ptr<cettest::TestPluginBase>,
    std::string>("TestPlugin", "Hi");
  BOOST_REQUIRE_EQUAL(p->message(), std::string("Hi"));
}

BOOST_AUTO_TEST_CASE(CheckFinder)
{
  auto fptr = pf.find<std::string>("TestPlugin",
                                   "pluginType",
                                   cet::PluginFactory::nothrow);
  BOOST_REQUIRE(fptr);
  BOOST_REQUIRE_EQUAL(fptr(),                                           \
                      PluginTypeDeducer<cettest::TestPluginBase>::value);
  BOOST_REQUIRE(pf.find<std::string>("TestPlugin",
                                     "oops",
                                     cet::PluginFactory::nothrow) == 0);
}

BOOST_AUTO_TEST_CASE(checkError)
{
  using namespace std::string_literals;
  BOOST_CHECK_EXCEPTION(pf.makePlugin<std::unique_ptr<cettest::TestPluginBase> >("TestPluginX"s, "Hi"s), \
                        cet::exception,                                 \
                        [](cet::exception const & e)                    \
                        {                                               \
                          return e.category() == "Configuration" &&     \
                            std::string(e.what()).find("ETERNAL") !=    \
                            std::string::npos;                          \
                        });
}

BOOST_AUTO_TEST_SUITE_END()
