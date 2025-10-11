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

## Getting Started
- [Installation](docs/install.md) 
- [Run and Eval](docs/eval.md)
- [Troubleshooting Tips](docs/common-errors.md)

## LM-Meter Performance & Overhead

### 1. Phase-level profiling accuracy on Pixel 8 Pro:

<table border="1" cellspacing="0" cellpadding="2" style="border-collapse: collapse; width:100%; text-align:center;">
  <thead>
    <tr>
      <th rowspan="2" style="border: 1px solid #000; padding: 2px;"><sub>Models</sub></th>
      <th rowspan="2" style="border: 1px solid #000; padding: 2px;"><sub>Phases</sub></th>
      <th colspan="2" style="border: 1px solid #000; padding: 2px;"><sub>Profiled latency (ms)</sub></th>
      <th rowspan="2" style="border: 1px solid #000; padding: 2px;"><sub>α (%)</sub></th>
      <th rowspan="2" style="border: 1px solid #000; padding: 2px;"><sub>ε★ (μs/ms)</sub></th>
    </tr>
    <tr>
      <th style="border: 1px solid #000; padding: 2px;"><sub>LM-METER</sub></th>
      <th style="border: 1px solid #000; padding: 2px;"><sub>AGI</sub></th>
    </tr>
  </thead>

  <tbody>
    <!-- Llama -->
    <tr>
      <td rowspan="7" style="border: 1px solid #000; padding: 2px; writing-mode: vertical-rl; transform: rotate(180deg);"><sub>Llama-3.2-3B-Instruct</sub></td>
      <td><sub>Embedding</sub></td><td><sub>0.8038</sub></td><td><sub>0.7763</sub></td><td><sub>96.46</sub></td><td><sub>35.412</sub></td>
    </tr>
    <tr><td><sub>Prefill</sub></td><td><sub>3433.8628</sub></td><td><sub>3433.8142</sub></td><td><sub>99.99</sub></td><td><sub>0.014</sub></td></tr>
    <tr><td><sub>Decode</sub></td><td><sub>62.5669</sub></td><td><sub>62.5303</sub></td><td><sub>99.94</sub></td><td><sub>0.585</sub></td></tr>
    <tr><td><sub>Softmax</sub></td><td><sub>142.6166</sub></td><td><sub>142.6542</sub></td><td><sub>99.97</sub></td><td><sub>0.264</sub></td></tr>
    <tr><td><sub>CopyProbsToCPU</sub></td><td><sub>0.4929</sub></td><td><sub>0.4616</sub></td><td><sub>93.22</sub></td><td><sub>67.718</sub></td></tr>
    <tr><td><sub>Sampling</sub></td><td><sub>0.0675</sub></td><td><sub>0.0824</sub></td><td><sub>81.86</sub></td><td><sub>181.439</sub></td></tr>
    <tr><td><b><sub>End-to-end</sub></b></td><td><b><sub>3640.4104</sub></b></td><td><b><sub>3640.3191</sub></b></td><td><b><sub>99.99</sub></b></td><td><b><sub>0.025</sub></b></td></tr>
    <!-- Gemma -->
    <tr>
      <td rowspan="7" style="border: 1px solid #000; padding: 2px; writing-mode: vertical-rl; transform: rotate(180deg);"><sub>Gemma-2-2B-it</sub></td>
      <td><sub>Embedding</sub></td><td><sub>0.7659</sub></td><td><sub>0.7398</sub></td><td><sub>96.48</sub></td><td><sub>35.226</sub></td>
    </tr>
    <tr><td><sub>Prefill</sub></td><td><sub>9301.1318</sub></td><td><sub>9301.0589</sub></td><td><sub>99.99</sub></td><td><sub>0.008</sub></td></tr>
    <tr><td><sub>Decode</sub></td><td><sub>54.5909</sub></td><td><sub>54.5557</sub></td><td><sub>99.94</sub></td><td><sub>0.646</sub></td></tr>
    <tr><td><sub>Softmax</sub></td><td><sub>502.3319</sub></td><td><sub>502.3698</sub></td><td><sub>99.99</sub></td><td><sub>0.076</sub></td></tr>
    <tr><td><sub>CopyProbsToCPU</sub></td><td><sub>0.5570</sub></td><td><sub>0.5255</sub></td><td><sub>94.02</sub></td><td><sub>59.829</sub></td></tr>
    <tr><td><sub>Sampling</sub></td><td><sub>0.1698</sub></td><td><sub>0.1830</sub></td><td><sub>92.76</sub></td><td><sub>72.365</sub></td></tr>
    <tr><td><b><sub>End-to-end</sub></b></td><td><b><sub>9859.5473</sub></b></td><td><b><sub>9859.4329</sub></b></td><td><b><sub>99.99</sub></b></td><td><b><sub>0.012</sub></b></td></tr>
  </tbody>
</table>

### 2. Kernel-level profiling accuracy on Pixel 8 Pro and Pixel 7:

<table border="1" cellspacing="0" cellpadding="2" style="border-collapse: collapse; width: 90%; text-align: center;">
  <thead>
    <tr>
      <th rowspan="2" style="border: 1px solid #000;"><sub>Kernels</sub></th>
      <th rowspan="2" style="border: 1px solid #000;"><sub>Phases</sub></th>
      <th colspan="4" style="border: 1px solid #000;"><sub>Google Pixel 8 Pro</sub></th>
      <th colspan="2" style="border: 1px solid #000;"><sub>Google Pixel 7</sub></th>
    </tr>
    <tr>
      <th colspan="2" style="border: 1px solid #000;"><sub>Profiled latency (ms)</sub></th>
      <th rowspan="1" style="border: 1px solid #000;"><sub>α (%)</sub></th>
      <th rowspan="1" style="border: 1px solid #000;"><sub>ε★ (μs/ms)</sub></th>
      <th rowspan="1" style="border: 1px solid #000;"><sub>α (%)</sub></th>
      <th rowspan="1" style="border: 1px solid #000;"><sub>ε★ (μs/ms)</sub></th>
    </tr>
    <tr>
      <th colspan="2" style="border: none;"></th>
      <th style="border: 1px solid #000;"><sub>LM-METER</sub></th>
      <th style="border: 1px solid #000;"><sub>GT</sub></th>
      <th colspan="3" style="border: none;"></th>
    </tr>
  </thead>

  <tbody>
    <!-- Prefill -->
    <tr><td><sub>dequantize1_NT_matmul5</sub></td><td rowspan="4" style="border: 1px solid #000;"><sub>Prefill</sub></td><td><sub>81.1899</sub></td><td><sub>82.1329</sub></td><td><sub>98.85</sub></td><td><sub>11.481</sub></td><td><sub>98.88</sub></td><td><sub>11.212</sub></td></tr>
    <tr><td><sub>dequantize2_NT_matmul6</sub></td><td><sub>31.3407</sub></td><td><sub>31.7568</sub></td><td><sub>98.69</sub></td><td><sub>13.103</sub></td><td><sub>95.18</sub></td><td><sub>48.209</sub></td></tr>
    <tr><td><sub>dequantize3_NT_matmul7</sub></td><td><sub>330.3757</sub></td><td><sub>332.7218</sub></td><td><sub>99.29</sub></td><td><sub>7.051</sub></td><td><sub>98.87</sub></td><td><sub>11.328</sub></td></tr>
    <tr><td><sub>dequantize4_NT_matmul8</sub></td><td><sub>367.5603</sub></td><td><sub>367.0284</sub></td><td><b><sub>99.86 (highest)</sub></b></td><td><sub>1.449</sub></td><td><sub>99.11</sub></td><td><sub>8.896</sub></td></tr>
    <!-- Decode -->
    <tr><td><sub>dequantize1_NT_matmul10</sub></td><td rowspan="9" style="border: 1px solid #000;"><sub>Decode</sub></td><td><sub>0.3643</sub></td><td><sub>0.3737</sub></td><td><sub>97.46</sub></td><td><sub>25.391</sub></td><td><sub>97.19</sub></td><td><sub>28.145</sub></td></tr>
    <tr><td><sub>dequantize2_NT_matmul11</sub></td><td><sub>0.2062</sub></td><td><sub>0.2006</sub></td><td><sub>97.23</sub></td><td><sub>27.706</sub></td><td><sub>98.14</sub></td><td><sub>18.587</sub></td></tr>
    <tr><td><sub>dequantize3_NT_matmul12</sub></td><td><sub>1.3813</sub></td><td><sub>1.3601</sub></td><td><sub>98.44</sub></td><td><sub>15.587</sub></td><td><sub>98.17</sub></td><td><sub>18.267</sub></td></tr>
    <tr><td><sub>dequantize4_NT_matmul13</sub></td><td><sub>0.6862</sub></td><td><sub>0.6586</sub></td><td><sub>95.81</sub></td><td><sub>41.921</sub></td><td><sub>97.50</sub></td><td><sub>25.044</sub></td></tr>
    <tr><td><sub>dequantize_NT_matmul14_divide2_tir_tanh2_multiply8</sub></td><td><sub>18.4379</sub></td><td><sub>18.3619</sub></td><td><sub>99.59</sub></td><td><sub>4.147</sub></td><td><sub>98.13</sub></td><td><sub>18.705</sub></td></tr>
    <tr><td><sub>add_norm_prefill</sub></td><td><sub>0.1149</sub></td><td><sub>0.1059</sub></td><td><b><sub>91.51 (lowest)</sub></b></td><td><sub>84.891</sub></td><td><sub>93.29</sub></td><td><sub>67.080</sub></td></tr>
    <tr><td><sub>rms_norm2</sub></td><td><sub>0.1037</sub></td><td><sub>0.1092</sub></td><td><sub>94.93</sub></td><td><sub>50.641</sub></td><td><sub>92.65</sub></td><td><sub>73.531</sub></td></tr>
    <tr><td><sub>split2_gelu_tanh2_multiply7</sub></td><td><sub>0.0952</sub></td><td><sub>0.0939</sub></td><td><sub>98.62</sub></td><td><sub>13.727</sub></td><td><sub>93.75</sub></td><td><sub>62.517</sub></td></tr>
    <tr><td><sub>multiply6</sub></td><td><sub>0.1061</sub></td><td><sub>0.1005</sub></td><td><sub>94.35</sub></td><td><sub>56.546</sub></td><td><b><sub>90.31</sub></b></td><td><sub>96.934</sub></td></tr>
    <!-- Softmax -->
    <tr><td><sub>chunk_lse</sub></td><td rowspan="2" style="border: 1px solid #000;"><sub>Softmax</sub></td><td><sub>0.2718</sub></td><td><sub>0.2839</sub></td><td><sub>95.53</sub></td><td><sub>44.735</sub></td><td><sub>99.39</sub></td><td><sub>6.026</sub></td></tr>
    <tr><td><sub>softmax_with_chunked_sum</sub></td><td><sub>0.2376</sub></td><td><sub>0.2392</sub></td><td><sub>99.33</sub></td><td><sub>6.689</sub></td><td><b><sub>99.40</sub></b></td><td><sub>5.992</sub></td></tr>
    <!-- Embedding -->
    <tr><td><sub>dequantize_take1</sub></td><td style="border: 1px solid #000;"><sub>Embedding</sub></td><td><sub>0.1034</sub></td><td><sub>0.1097</sub></td><td><sub>94.26</sub></td><td><sub>57.429</sub></td><td><sub>95.73</sub></td><td><sub>42.676</sub></td></tr>
  </tbody>
</table>



## Acknowledgement

Many thanks to these excellent open source projects:
- [MLC LLM](https://llm.mlc.ai/) 
- [tvm](https://github.com/apache/tvm)