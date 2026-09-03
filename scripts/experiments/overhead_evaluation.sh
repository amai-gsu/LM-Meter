# =================Pure Profiling=================================
# Step 0: Run experiments/set_cpu_gpu_governors.sh to fix CPU and GPU frequencies
# Step 1: Comment out the following codes in /mlc-llm-inf/cpp/serve/threaded_engine.cc
#     // Optional<EventTraceRecorder> trace_recorder = EventTraceRecorder::Create();
#     // if (trace_recorder.defined()) {
#     //   LOG(INFO) << "[Tracing] EventTraceRecorder is enabled.";
#     // } else {
#     //   LOG(INFO) << "[Tracing] No trace recorder provided.";
#     // }
#     // Result<EngineCreationOutput> output_res =
#     //     Engine::Create(engine_config_json_str, device_, request_stream_callback, trace_recorder);
# Step 2: Build using build_all_e2e_pure.sh

# =================LM-Meter Profiling=================================
# Step 0: Run experiments/set_cpu_gpu_governors.sh to fix CPU and GPU frequencies
# Step 1: Comment out the following codes in /mlc-llm-inf/cpp/serve/threaded_engine.cc
#     // Result<EngineCreationOutput> output_res =
#       //Engine::Create(engine_config_json_str, device_, request_stream_callback, trace_recorder_);
# Use:
    # Optional<EventTraceRecorder> trace_recorder = EventTraceRecorder::Create();
    # if (trace_recorder.defined()) {
    #   LOG(INFO) << "[Tracing] EventTraceRecorder is enabled.";
    # } else {
    #   LOG(INFO) << "[Tracing] No trace recorder provided.";
    # }
    # Result<EngineCreationOutput> output_res =
    #     Engine::Create(engine_config_json_str, device_, request_stream_callback, trace_recorder);
# Step 2: Build using build_all_e2e_plus_opencl_kernel.sh

# =================Melting Point Profiling=================================
# Step 0: Run experiments/set_cpu_gpu_governors.sh to fix CPU and GPU frequencies
# Step 1: Comment out the following codes in /mlc-llm-inf/cpp/serve/threaded_engine.cc
#     // Result<EngineCreationOutput> output_res =
#       //Engine::Create(engine_config_json_str, device_, request_stream_callback, trace_recorder_);
# Step 2: Recover the following codes in /mlc-llm-inf/cpp/serve/threaded_engine.cc
    # Optional<EventTraceRecorder> trace_recorder = EventTraceRecorder::Create();
    # if (trace_recorder.defined()) {
    #   LOG(INFO) << "[Tracing] EventTraceRecorder is enabled.";
    # } else {
    #   LOG(INFO) << "[Tracing] No trace recorder provided.";
    # }
    # Result<EngineCreationOutput> output_res =
    #     Engine::Create(engine_config_json_str, device_, request_stream_callback, trace_recorder);
# Step 3: Build using build_all_relax_op_pure.sh