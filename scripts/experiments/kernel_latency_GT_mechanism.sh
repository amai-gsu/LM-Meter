#
# ==================================================================================
# In order to evaluate the accuracy of kernel-level inference latency 
# profiling, we propose and implement a kernel duplication and injection mechanism:
# My target is to implement kernel injection, where duplicating a kernel and 
# inject it immediately after the original kernel. So that I can profile the inference 
# latency ground truth for this kernel through the end-to-end latency with injected 
# kernel subtracting the end-to-end latency without the injection. 
# ==================================================================================

# =================Profiling with duplicated kernel=================================
# Step 1: go to python/mlc_llm/compiler_pass/pipeline.py
        # Set KERNEL_DUPLICATION = True
# Step 2: go to python/mlc_llm/compiler_pass/kernel_duplicate_inject.py
        # Set TARGET_KERNEL = "fused_dequantize1_NT_matmul10" or other kernels
        # Set NUM_DUPS, number of duplications
# Step 3: go to python/mlc_llm/compiler_pass/scatter_tuple_get_item.py
        # Comment out updated_func = remove_all_unused(updated_func)
# Step 4: go to python/mlc_llm/compiler_pass/lift_global_buffer_alloc.py
        # Comment out updated_func = remove_all_unused(updated_func)
        # Replace out return relax.transform.DeadCodeElimination()(mod) with return mod
# Step 5: go to android/MLCChat/mlc-package-config.json
        # Add "model_lib": "gemma2_q4f16_1_duplicate_<TARGET_KERNEL>_<NUM_DUPS>",
# Step 6: Set chat engine configurations in mlc-llm-inf/android/MLCChat/app/src/main/java/ai/mlc/mlcchat/AppViewModel.kt
        # Specifically, max_tokens, stop, seed, temperature, top_p
# Step 7: run ./build_all_e2e_plus_opencl_kernel.sh
# Step 8: Set CPU and GPU frequency for mobile device
        # follow the instructions in scripts/experiments/set_cpu_gpu_performance.sh

# ==================================================================================

# =================Profiling with normal pipeline=================================
# Step 1: go to python/mlc_llm/compiler_pass/pipeline.py
        # Set KERNEL_DUPLICATION = False
# Step 2: go to python/mlc_llm/compiler_pass/scatter_tuple_get_item.py
        # Recover updated_func = remove_all_unused(updated_func)
# Step 4: go to python/mlc_llm/compiler_pass/lift_global_buffer_alloc.py
        # Recover updated_func = remove_all_unused(updated_func)
        # Recover return relax.transform.DeadCodeElimination()(mod)
# Step 5: go to android/MLCChat/mlc-package-config.json
        # Remove "_duplicate" in "model_lib": "gemma2_q4f16_1_duplicate",
# Step 6: Set chat engine configurations in mlc-llm-inf/android/MLCChat/app/src/main/java/ai/mlc/mlcchat/AppViewModel.kt
        # Specifically, max_tokens, stop, seed, temperature, top_p
# Step 7: run ./build_all_e2e_plus_opencl_kernel.sh
# Step 8: Set CPU and GPU frequency for mobile device
        # follow the instructions in scripts/experiments/set_cpu_gpu_performance.sh
# ==================================================================================