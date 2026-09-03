# ==================================================================================
# In order to evaluate the accuracy of phase-level (prefill, decode) inference latency 
# profiling, we integrate perfetto_sdk into MLC-LLM source code
# ==================================================================================

# =============================Step1=========================================
# Clone perfetto source code into 3rdparty
# cd 3rdparty
# git clone --depth 1 --branch v50.1 https://github.com/google/perfetto.git 3rdparty/perfetto

# =============================Step2=========================================
# Wire perfetto into CMake & Modify top-level CMakeLists.txt
        #============Add Perfetto===========================
        # find_package(Threads REQUIRED)
        #========================
        #============Add Perfetto===========================
        # #  Perfetto SDK (single amalgamated file)
        # #  The SDK lives in 3rdparty/perfetto as recommended by the official docs:
        # #  git clone https://github.com/google/perfetto.git -b v50.1 3rdparty/perfetto
        # #  Only 3rdparty/perfetto/sdk/perfetto.{h,cc} are required but we keep the
        # #  whole tag for simplicity.

        # add_library(perfetto_sdk STATIC 3rdparty/perfetto/sdk/perfetto.cc)
        # target_include_directories(perfetto_sdk PUBLIC 3rdparty/perfetto/sdk)
        # target_link_libraries(perfetto_sdk PUBLIC Threads::Threads)

        # # On MSVC the object is big; Perfetto docs suggest /bigobj
        # if (MSVC)
        # target_compile_options(perfetto_sdk PRIVATE "/bigobj")
        # endif()

        # # Enable hidden visibility everywhere (already done for other libs)
        # target_compile_options(perfetto_sdk PRIVATE ${MLC_VISIBILITY_FLAG})
        #========================
        #============Add Perfetto===========================
        # # Link Perfetto into all native targets that need tracing
        # target_link_libraries(mlc_llm_objs  PRIVATE perfetto_sdk)
        # target_link_libraries(mlc_llm       PRIVATE perfetto_sdk)
        # target_link_libraries(mlc_llm_static PRIVATE perfetto_sdk)
        # target_link_libraries(mlc_llm_module PRIVATE perfetto_sdk)
        #========================

# =============================Step3=========================================
# Initialize Perfetto once at startup
# Create cpp/trace_init.cc and add:
#include <perfetto.h>
# // 1. Category table (compile-time, exactly once)
# PERFETTO_DEFINE_CATEGORIES(
#   perfetto::Category("mlc").SetDescription("MLC-LLM phases")
# );
# PERFETTO_TRACK_EVENT_STATIC_STORAGE();
# // 2. Runtime bootstrap
# static void InitPerfettoOnce() {
#   static bool inited = false;
#   if (inited) return;
#   inited = true;

#   perfetto::TracingInitArgs args;
#   args.backends |= perfetto::kInProcessBackend;   // desktop / fallback
#   args.backends |= perfetto::kSystemBackend;      // Android Q+ system daemon
#   perfetto::Tracing::Initialize(args);
#   perfetto::TrackEvent::Register();               // connect TRACE_EVENT
# }
# extern "C" void mlc_init_tracing() { InitPerfettoOnce(); }

# =============================Step4=========================================
# Declare categories
# For example in cpp/serve/model.cc:
# #include <perfetto.h>//Perfetto
# PERFETTO_DEFINE_CATEGORIES(
#   perfetto::Category("mlc").SetDescription("MLC-LLM phases") //Perfetto
# );
# =============================Step5=========================================
# Instrument key phases
# E.g.,: TRACE_EVENT("mlc", "mlc_embedding");
# =============================Step6=========================================
# Configure AGI
# Add this to enable trace "mlc" category
# data_sources {
#   config {
#     name: "track_event"
#     track_event_config {
#       disabled_categories: "*"
#       enabled_categories: "mlc"
#     }
#   }
# }
