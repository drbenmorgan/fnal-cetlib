#include "cetlib/SimultaneousFunctionSpawner.h"
#include "cetlib/assert_only_one_thread.h"

#include <chrono>
#include <thread>

using namespace cet;
using namespace std::chrono_literals;

int main()
{
  CET_ASSERT_ONLY_ONE_THREAD();
  auto will_fail = []{
    // Insert "by-hand" what the CET_ASSERT_ONLY_ONE_THREAD would
    // expand to so that we can avoid an std::abort() for testing.
    static cet::detail::ThreadCounter s {__FILE__, __LINE__, __func__};
    cet::detail::ThreadCounter::Sentry hold {s, false};
    std::this_thread::sleep_for(1ms);
  };
  SimultaneousFunctionSpawner launch {repeated_task(2u, will_fail)};
}
