#include <perfetto.h>

// 1. Category table (compile-time, exactly once)
PERFETTO_DEFINE_CATEGORIES(
  perfetto::Category("mlc").SetDescription("MLC-LLM phases")
);
PERFETTO_TRACK_EVENT_STATIC_STORAGE();

// 2. Runtime bootstrap
static void InitPerfettoOnce() {
  static bool inited = false;
  if (inited) return;
  inited = true;

  perfetto::TracingInitArgs args;
  args.backends |= perfetto::kInProcessBackend;   // desktop / fallback
  args.backends |= perfetto::kSystemBackend;      // Android Q+ system daemon
  perfetto::Tracing::Initialize(args);
  perfetto::TrackEvent::Register();               // connect TRACE_EVENT
}

extern "C" void mlc_init_tracing() { InitPerfettoOnce(); }
