<div align="center">

# LM-Meter  
[![Installation](https://img.shields.io/badge/docs-latest-green)](https://github.com/amai-gsu/lm-Meter-Private-Experiment/tree/main/docs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![AMAI Lab](https://img.shields.io/badge/AMAI%20Lab-GSU-blue)](https://www.amai-gsu.us/)

**Online Kernel-Level Profiler for On-Device LLMs**

[Get Started](docs/install.md) | [📘 Documentation](docs/) | [📑 Paper](https://www.amai-gsu.us/wp-content/uploads/2025/lm-meter.pdf) | [🎥 Demo Video](#) (coming soon) | [🖥️ Slides](#) (coming soon)

</div>

## About
LM-Meter is a lightweight, online profiler for large language models (LLMs) running on mobile and edge devices. The mission of this project is to provide fine-grained, real-time visibility into on-device LLM inference at both phase and kernel levels, enabling researchers and developers to understand performance-efficiency trade-offs, identify bottlenecks, and systematically optimize models for resource-constrained platforms.

<div align="center">
<p align="center">
  ✅ Released &nbsp;&nbsp;|&nbsp;&nbsp; 🚧 Coming Soon &nbsp;&nbsp;|&nbsp;&nbsp; ❌ Not Supported
</p>
<table style="width:100%; text-align:center;">
  <thead>
    <tr>
      <th style="width:15%"></th>
      <th style="width:20%">Android GPU<br/><sub>OpenCL</sub></th>
      <th style="width:20%">iOS GPU<br/><sub>Metal</sub></th>
      <th style="width:20%">NVIDIA Jetson<br/><sub>CUDA / Vulkan</sub></th>
      <th style="width:20%">Coral TPU<br/></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>MLC LLM</b></td>
      <td align="center">✅</td>
      <td align="center">🚧</td>
      <td align="center">🚧</td>
      <td align="center">❌</td>
    </tr>
    <tr>
      <td><b>llama.cpp</b></td>
      <td align="center">🚧</td>
      <td align="center">🚧</td>
      <td align="center">🚧</td>
      <td align="center">❌</td>
    </tr>
    <tr>
      <td><b>vLLM</b></td>
      <td align="center">❌</td>
      <td align="center">❌</td>
      <td align="center">🚧</td>
      <td align="center">🚧</td>
    </tr>
  </tbody>
</table>
</div>

## Getting Started
- [Installation](docs/install.md) 
- [Run and Eval](docs/eval.md)
- [Troubleshooting Tips](docs/common-errors.md)

## LM-Meter Performance & Overhead

### 1. Phase-level profiling accuracy on Pixel 8 Pro:

| **Models** | **Phases** | **Profiled latency (ms)**<br>LM-METER | **Profiled latency (ms)**<br>AGI | **α (%)** | **ε★ (μs/ms)** |
|-------------|------------|----------------------------------|----------------------------------|-------------|----------------|
| **Llama-3.2–3B-Instruct** | Embedding | 0.8038 | 0.7763 | 96.46 | 35.412 |
|  | Prefill | 3433.8628 | 3433.8142 | 99.99 | 0.014 |
|  | Decode | 62.5669 | 62.5303 | 99.94 | 0.585 |
|  | Softmax | 142.6166 | 142.6542 | 99.97 | 0.264 |
|  | CopyProbsToCPU | 0.4929 | 0.4616 | 93.22 | 67.718 |
|  | Sampling | 0.0675 | 0.0824 | 81.86 | 181.439 |
|  | **End-to-end** | **3640.4104** | **3640.3191** | **99.99** | **0.025** |
| **Gemma-2–2B-it** | Embedding | 0.7659 | 0.7398 | 96.48 | 35.226 |
|  | Prefill | 9301.1318 | 9301.0589 | 99.99 | 0.008 |
|  | Decode | 54.5909 | 54.5557 | 99.94 | 0.646 |
|  | Softmax | 502.3319 | 502.3698 | 99.99 | 0.076 |
|  | CopyProbsToCPU | 0.5570 | 0.5255 | 94.02 | 59.829 |
|  | Sampling | 0.1698 | 0.1830 | 92.76 | 72.365 |
|  | **End-to-end** | **9859.5473** | **9859.4329** | **99.99** | **0.012** |
| **DeepSeek–R1-Distill-Qwen-1.5B** | Embedding | 0.6753 | 0.6531 | 96.60 | 33.975 |
|  | Prefill | 7630.7553 | 7630.6979 | 99.99 | 0.008 |
|  | Decode | 49.3840 | 49.3499 | 99.93 | 0.690 |
|  | Softmax | 437.0047 | 437.0459 | 99.99 | 0.094 |
|  | CopyProbsToCPU | 0.4206 | 0.3888 | 91.84 | 81.565 |
|  | Sampling | 0.0671 | 0.0786 | 85.41 | 145.949 |
|  | **End-to-end** | **8118.3069** | **8118.2143** | **99.99** | **0.011** |

### 2. Kernel-level profiling accuracy on Pixel 8 Pro and Pixel 7:

| **Kernels** | **Phases** | **Profiled latency (ms)**<br>LM-METER | **Profiled latency (ms)**<br>GT | **α (%)** | **ε★ (μs/ms)** | **α (%) (Pixel 7)** | **ε★ (μs/ms) (Pixel 7)** |
|--------------|-------------|--------------------------------------|---------------------------------|-------------|----------------|-------------------------|------------------------------|
| **Prefill** |  |  |  |  |  |  |  |
| dequantize1_NT_matmul5 |  | 81.1899 | 82.1329 | 98.85 | 11.481 | 98.88 | 11.212 |
| dequantize2_NT_matmul6 |  | 31.3407 | 31.7568 | 98.69 | 13.103 | 95.18 | 48.209 |
| dequantize3_NT_matmul7 |  | 330.3757 | 332.7218 | 99.29 | 7.051 | 98.87 | 11.328 |
| dequantize4_NT_matmul8 |  | 367.5603 | 367.0284 | **99.86 (highest)** | 1.449 | 99.11 | 8.896 |
| **Decode** |  |  |  |  |  |  |  |
| dequantize1_NT_matmul10 |  | 0.3643 | 0.3737 | 97.46 | 25.391 | 97.19 | 28.145 |
| dequantize2_NT_matmul11 |  | 0.2062 | 0.2006 | 97.23 | 27.706 | 98.14 | 18.587 |
| dequantize3_NT_matmul12 |  | 1.3813 | 1.3601 | 98.44 | 15.587 | 98.17 | 18.267 |
| dequantize4_NT_matmul13 |  | 0.6862 | 0.6586 | 95.81 | 41.921 | 97.50 | 25.044 |
| dequantize_NT_matmul14_divide2_tir_tanh2_multiply8 |  | 18.4379 | 18.3619 | 99.59 | 4.147 | 98.13 | 18.705 |
| add_norm_prefill |  | 0.1149 | 0.1059 | **91.51 (lowest)** | 84.891 | 93.29 | 67.080 |
| rms_norm2 |  | 0.1037 | 0.1092 | 94.93 | 50.641 | 92.65 | 73.531 |
| split2_gelu_tanh2_multiply7 |  | 0.0952 | 0.0939 | 98.62 | 13.727 | 93.75 | 62.517 |
| multiply6 |  | 0.1061 | 0.1005 | 94.35 | 56.546 | **90.31** | 96.934 |
| **Softmax** |  |  |  |  |  |  |  |
| chunk_lse |  | 0.2718 | 0.2839 | 95.53 | 44.735 | 99.39 | 6.026 |
| softmax_with_chunked_sum |  | 0.2376 | 0.2392 | 99.33 | 6.689 | **99.40** | 5.992 |
| **Embedding** |  |  |  |  |  |  |  |
| dequantize_take1 |  | 0.1034 | 0.1097 | 94.26 | 57.429 | 95.73 | 42.676 |

### 3. Kernel-level profiling accuracy on Pixel 8 Pro:

## Bibtex
If this work is helpful for your research, please consider citing the following BibTeX entry.

```
@inproceedings{wang2025sec,
  author    = {Wang, Haoxin and Tu, Xiaolong and Ke, Hongyu and Chai, Huirong and Chen, Dawei and Han, Kyungtae},
  title     = {lm-Meter: Unveiling Runtime Inference Latency for On-Device Language Models},
  booktitle = {Proc. The Tenth ACM/IEEE Symposium on Edge Computing (SEC)},
  pages     = {1--17},
  year      = {2025},
}
```

## Acknowledgement

Many thanks to these excellent open source projects:
- [MLC LLM](https://llm.mlc.ai/) 
- [tvm](https://github.com/apache/tvm)