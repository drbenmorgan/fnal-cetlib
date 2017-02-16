#ifndef cetlib_SimultaneousFunctionSpawner_h
#define cetlib_SimultaneousFunctionSpawner_h

//=================================================================
// The 'SimultaneousFunctionSpawner' is intended for testing the
// behavior under simultaneous execution of a supplied functor.  This
// class should be used in the following pattern (e.g.):
//
//   std::atomic<unsigned> nTimesCalled {0u};
//   auto task = [&counter]{ ++counter; };
//   cet::SimultaneousFunctionSpawner<7u> sps {task};
//   std::cout << nTimesCalled << '\n'; // Will print out '7'.
//
// Note that the template argument is the number of threads requested
// for concurrently running the task.
//
// The waiting mechanism here could be replaced with a
// condition_variable, similar to what Chris Green implemented in
// wirecap-libs/Barrier.hpp.
// =================================================================

#include <atomic>
#include <thread>
#include <vector>

namespace cet {

  template <unsigned Nthreads>
  class SimultaneousFunctionSpawner {
  public:

    template <typename FunctionToSpawn>
    SimultaneousFunctionSpawner(FunctionToSpawn f)
    {
      std::vector<std::thread> threads;
      auto wrapped_function = [this,f]{ execute(f); };
      for (unsigned i {}; i < Nthreads; ++i) {
        threads.emplace_back(wrapped_function);
      }

      for (auto& thread : threads)
        thread.join();
    }

  private:

    template <typename FunctionToSpawn>
    void execute(FunctionToSpawn f) {
      --counter_;
      while (counter_ != 0);
      f();
    }

    std::atomic<unsigned> counter_{Nthreads};
  };

}

#endif

// Local variables:
// mode: c++
// End:
