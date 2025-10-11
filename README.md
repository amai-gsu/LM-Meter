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
| **TinyLlama–1.1B-Chat-v1.0** | Embedding | 0.6858 | 0.6636 | 96.66 | 33.428 |
|  | Prefill | 5023.1182 | 5023.0765 | 99.99 | 0.008 |
|  | Decode | 34.6845 | 34.6534 | 99.91 | 0.897 |
|  | Softmax | 188.1463 | 188.1779 | 99.98 | 0.168 |
|  | CopyProbsToCPU | 0.3887 | 0.3602 | 92.10 | 78.980 |
|  | Sampling | 0.0504 | 0.0669 | 75.36 | 246.372 |
|  | **End-to-end** | **5247.0738** | **5246.9985** | **99.99** | **0.014** |
| **DeepSeek–R1-Distill-Qwen-1.5B** | Embedding | 0.6753 | 0.6531 | 96.60 | 33.975 |
|  | Prefill | 7630.7553 | 7630.6979 | 99.99 | 0.008 |
|  | Decode | 49.3840 | 49.3499 | 99.93 | 0.690 |
|  | Softmax | 437.0047 | 437.0459 | 99.99 | 0.094 |
|  | CopyProbsToCPU | 0.4206 | 0.3888 | 91.84 | 81.565 |
|  | Sampling | 0.0671 | 0.0786 | 85.41 | 145.949 |
|  | **End-to-end** | **8118.3069** | **8118.2143** | **99.99** | **0.011** |
| **SmolLM2–360M-Instruct** | Embedding | 0.9844 | 0.9671 | 98.21 | 17.909 |
|  | Prefill | 2399.3860 | 2399.3246 | 99.99 | 0.026 |
|  | Decode | 44.7612 | 44.7377 | 99.95 | 0.527 |
|  | Softmax | 221.8416 | 221.8672 | 99.99 | 0.116 |
|  | CopyProbsToCPU | 0.3081 | 0.2854 | 92.05 | 79.532 |
|  | Sampling | 0.0300 | 0.0394 | 76.06 | 239.395 |
|  | **End-to-end** | **2667.3113** | **2667.2214** | **99.99** | **0.034** |




### 2. Kernel-level profiling accuracy on Pixel 8 Pro and Pixel 7:

![Kernel-level runtime latency profiling results on Google Pixel 8 Pro and Pixel 7](docs/assets/kernel.png)


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