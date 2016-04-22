#include "TestPluginBase.h"

#include "cetlib/PluginTypeDeducer.h"

#include <memory>

namespace cettest {
  class TestPlugin;
}

class cettest::TestPlugin : public TestPluginBase {
public:
  TestPlugin(std::string message);
};

cettest::TestPlugin::
TestPlugin(std::string message)
:
  TestPluginBase(std::move(message))
{
}

extern "C" {
  std::unique_ptr<cettest::TestPluginBase>
  makePlugin(std::string message)
  {
    return std::make_unique<cettest::TestPlugin>(std::move(message));
  }
}

DEFINE_BASIC_PLUGINTYPE_FUNC(cettest::TestPluginBase)
