#define BOOST_TEST_MODULE (exception_test)

#include "cetlib/quiet_unit_test.hpp"

#include "cetlib/exception.h"

#include <cstdlib>
#include <iostream>
#include <string>


using cet::exception;


struct my_exception
  : public cet::exception
{

  my_exception( Category const & category )
    : cet::exception( category )
  { }

};  // my_exception

BOOST_AUTO_TEST_SUITE(exception_test)

BOOST_AUTO_TEST_CASE(simple_category_check)
{
  BOOST_CHECK_EQUAL(exception("Test").category(), std::string("Test"));
}

BOOST_AUTO_TEST_CASE(exception_text_check_01)
{
  exception e("Hello");
  e << "I greet you." << 16 << std::endl;
  BOOST_CHECK_EQUAL(e.category(), std::string("Hello"));
  BOOST_CHECK_NE(e.explain_self().find("I greet you.16\n"), std::string::npos);
}

BOOST_AUTO_TEST_CASE(exception_test_check_02)
{
  try {
    throw exception("Bye") << "Nice meeting you" << std::endl;
  } catch( exception const & e ) {
    BOOST_CHECK_EQUAL(e.category(), std::string("Bye"));
    BOOST_CHECK_NE(e.explain_self().find("Nice meeting you\n"), std::string::npos);
  }
}

BOOST_AUTO_TEST_CASE(exception_subclass_01)
{
  BOOST_CHECK_EQUAL(my_exception("Test").category(), std::string("Test"));
}

BOOST_AUTO_TEST_CASE(exception_subclass_02)
{
  my_exception e("Hello");
  BOOST_CHECK_EQUAL(e.category(), std::string("Hello"));
}

BOOST_AUTO_TEST_CASE(exception_subclass_03)
{
  BOOST_CHECK_EXCEPTION(throw my_exception("Bye") << "Nice meeting you" << std::endl, \
                        my_exception,                                   \
                        [](my_exception const & e) -> bool {            \
                          return e.explain_self().find("Nice meeting you\n") != std::string::npos;
                        });
}

BOOST_AUTO_TEST_CASE(nesting)
{
  exception e3("Innermost");
  e3 << "Tiny";
  exception e2("Inner", "", e3);
  e2 << "Secondary\nmultiline\nmessage.\n";
  exception e1("Outer", "", e2);
  e1 << "Initial\nmultiline\nmessage.\n";
  std::string wanted("---- Outer BEGIN\n  ---- Inner BEGIN\n    ---- Innermost BEGIN\n      Tiny\n    ---- Innermost END\n    Secondary\n    multiline\n    message.\n  ---- Inner END\n  Initial\n  multiline\n  message.\n---- Outer END\n");
  BOOST_CHECK_EQUAL(wanted, e1.explain_self());
  auto wanted_categories = { std::string("Outer"), std::string("Inner"), std::string("Innermost") };
  BOOST_CHECK_EQUAL_COLLECTIONS(wanted_categories.begin(), wanted_categories.end(), e1.history().begin(), e1.history().end());
  BOOST_CHECK_EQUAL(e1.root_cause(), std::string("Innermost"));
  BOOST_CHECK_EQUAL(e2.root_cause(), std::string("Innermost"));
}

BOOST_AUTO_TEST_SUITE_END()
