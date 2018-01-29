#ifndef SKSKKJAD_SDADS_ASD
#define SKSKKJAD_SDADS_ASD

#include "cetlib/compiler_macros.h"

#define MAKE_PLUGIN_START(result_type, ...) \
  EXTERN_C_FUNC_DECLARE_START result_type makePlugin(__VA_ARGS__)
#define MAKE_PLUGIN_END EXTERN_C_FUNC_DECLARE_END

#endif
