#!/bin/bash
# chmod +x /Users/haoxinwang/mobileLLM/Neurips25/scripts/build_mlc_inference.sh
#================================================================
# Build mlc_llm without kernel-level profiler
#================================================================

# Exports
# export TVM_HOME="/Users/haoxinwang/mobileLLM/MLC_krl/tvm-v0_20_dev0_opencl"
# export MLC_HOME="/Users/haoxinwang/mobileLLM/MLC_krl/mlc-llm-inf"
# export KERNEL_LEVEL_PROFILE="0"
export CMAKE_INCLUDE_PATH="/Users/haoxinwang/mobileLLM/OpenCL-Headers"

if [[ $(uname -r) == *tegra ]]; then
    export IS_JETSON="1"
else
    export IS_JETSON="0"
fi

configure_cmake() {
    echo "Configuring cmake"
    rm -rf build
    mkdir -p build;

    pushd build/
    touch config.cmake
    echo "set(TVM_HOME $TVM_HOME)" >> config.cmake
    echo "set(CMAKE_BUILD_TYPE RelWithDebInfo)" >> config.cmake
    echo "set(USE_VULKAN OFF)" >> config.cmake
    if [ "$IS_JETSON" == "1" ]; then
        echo "set(CMAKE_CXX_STANDARD 17)" >> config.cmake
        echo "set(CMAKE_CUDA_STANDARD 17)" >> config.cmake
        echo "set(CMAKE_CUDA_ARCHITECTURES \"72;87\")" >> config.cmake
        echo "set(USE_CUDA ON)" >> config.cmake
        echo "set(USE_CUDNN ON)" >> config.cmake
        echo "set(USE_CUBLAS ON)" >> config.cmake
        echo "set(USE_CURAND ON)" >> config.cmake
        echo "set(USE_CUTLASS ON)" >> config.cmake
        echo "set(USE_THRUST ON)" >> config.cmake
        echo "set(USE_GRAPH_EXECUTOR_CUDA_GRAPH ON)" >> config.cmake
        echo "set(USE_STACKVM_RUNTIME ON)" >> config.cmake
        echo "set(USE_LLVM \"/usr/bin/llvm-config --link-static\")" >> config.cmake
        echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake
        echo "set(SUMMARIZE ON)" >> config.cmake
    else
        echo "set(USE_CUDA   OFF)" >> config.cmake
        echo "set(USE_METAL  ON)" >> config.cmake
        echo "set(USE_OPENCL ON)" >> config.cmake
    fi
    popd
}

build() {
    echo "Building MLC"
    pushd build/
    if [ "$KERNEL_LEVEL_PROFILE" == "1" ]; then
        echo "Building with kernel-level profiling"
        cmake -DKERNEL_LEVEL_PROFILE=1 -DTVM_SOURCE_DIR="$TVM_HOME" .. && cmake --build . --parallel 4
    else
        echo "Building without kernel-level profiling"
        cmake -DTVM_SOURCE_DIR="$TVM_HOME" .. && cmake --build . --parallel 4
    fi
    popd
}

# Install python
install_python_package() {
    echo "Installing python package"
    pushd python
    pip install -e .
    popd
}

cd $MLC_HOME
configure_cmake && \
build && \
install_python_package