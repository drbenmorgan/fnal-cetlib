cet_test(connection_t LIBRARIES pthread)
cet_test(create_table_ddl_t)
cet_test(insert_t)
cet_test(ntuple_t LIBRARIES pthread)
cet_test(query_result_t)
cet_test(statistics_t)
cet_test(transaction_t
  TEST_PROPERTIES
  PASS_REGULAR_EXPRESSION "Transaction d'tor called before commit was called.")
