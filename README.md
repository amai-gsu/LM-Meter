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
<table border="1" style="border-collapse: collapse; width:100%; text-align:center;">
  <thead>
    <tr>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;">Models</th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;">Phases</th>
      <th colspan="2" style="border: 1px solid #000; padding: 4px;">Profiled latency (ms)</th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;">α (%)</th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;">ε★ (μs/ms)</th>
    </tr>
    <tr>
      <th style="border: 1px solid #000; padding: 4px;">LM-METER</th>
      <th style="border: 1px solid #000; padding: 4px;">AGI</th>
    </tr>
  </thead>
  <tbody>
    <!-- Llama -->
    <tr>
      <td rowspan="7" style="border: 1px solid #000; padding: 4px; writing-mode: vertical-rl; transform: rotate(180deg);">Llama-3.2-3B-Instruct</td>
      <td>Embedding</td><td>0.8038</td><td>0.7763</td><td>96.46</td><td>35.412</td>
    </tr>
    <tr><td>Prefill</td><td>3433.8628</td><td>3433.8142</td><td>99.99</td><td>0.014</td></tr>
    <tr><td>Decode</td><td>62.5669</td><td>62.5303</td><td>99.94</td><td>0.585</td></tr>
    <tr><td>Softmax</td><td>142.6166</td><td>142.6542</td><td>99.97</td><td>0.264</td></tr>
    <tr><td>CopyProbsToCPU</td><td>0.4929</td><td>0.4616</td><td>93.22</td><td>67.718</td></tr>
    <tr><td>Sampling</td><td>0.0675</td><td>0.0824</td><td>81.86</td><td>181.439</td></tr>
    <tr><td><b>End-to-end</b></td><td><b>3640.4104</b></td><td><b>3640.3191</b></td><td><b>99.99</b></td><td><b>0.025</b></td></tr>
    <!-- Gemma -->
    <tr>
      <td rowspan="7" style="border: 1px solid #000; padding: 4px; writing-mode: vertical-rl; transform: rotate(180deg);">Gemma-2-2B-it</td>
      <td>Embedding</td><td>0.7659</td><td>0.7398</td><td>96.48</td><td>35.226</td>
    </tr>
    <tr><td>Prefill</td><td>9301.1318</td><td>9301.0589</td><td>99.99</td><td>0.008</td></tr>
    <tr><td>Decode</td><td>54.5909</td><td>54.5557</td><td>99.94</td><td>0.646</td></tr>
    <tr><td>Softmax</td><td>502.3319</td><td>502.3698</td><td>99.99</td><td>0.076</td></tr>
    <tr><td>CopyProbsToCPU</td><td>0.5570</td><td>0.5255</td><td>94.02</td><td>59.829</td></tr>
    <tr><td>Sampling</td><td>0.1698</td><td>0.1830</td><td>92.76</td><td>72.365</td></tr>
    <tr><td><b>End-to-end</b></td><td><b>9859.5473</b></td><td><b>9859.4329</b></td><td><b>99.99</b></td><td><b>0.012</b></td></tr>
  </tbody>
</table>

<table border="1" cellspacing="-2" cellpadding="-2" style="border-collapse: collapse; width:100%; text-align:center;">
  <thead>
    <tr>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;"><sub><sub>Models</sub></sub></th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;"><sub><sub>Phases</sub></sub></th>
      <th colspan="2" style="border: 1px solid #000; padding: 4px;"><sub><sub>Profiled latency (ms)</sub></sub></th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;"><sub><sub>α (%)</sub></sub></th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;"><sub><sub>ε★ (μs/ms)</sub></sub></th>
    </tr>
    <tr>
      <th style="border: 1px solid #000; padding: 4px;"><sub><sub>LM-METER</sub></sub></th>
      <th style="border: 1px solid #000; padding: 4px;"><sub><sub>AGI</sub></sub></th>
    </tr>
  </thead>

  <tbody>
    <!-- Llama -->
    <tr>
      <td rowspan="7" style="border: 1px solid #000; padding: 4px; writing-mode: vertical-rl; transform: rotate(180deg);"><sub><sub>Llama-3.2-3B-Instruct</sub></sub></td>
      <td><sub><sub>Embedding</sub></sub></td><td><sub><sub>0.8038</sub></sub></td><td><sub><sub>0.7763</sub></sub></td><td><sub><sub>96.46</sub></sub></td><td><sub><sub>35.412</sub></sub></td>
    </tr>
    <tr><td><sub><sub>Prefill</sub></sub></td><td><sub><sub>3433.8628</sub></sub></td><td><sub><sub>3433.8142</sub></sub></td><td><sub><sub>99.99</sub></sub></td><td><sub><sub>0.014</sub></sub></td></tr>
    <tr><td><sub><sub>Decode</sub></sub></td><td><sub><sub>62.5669</sub></sub></td><td><sub><sub>62.5303</sub></sub></td><td><sub><sub>99.94</sub></sub></td><td><sub><sub>0.585</sub></sub></td></tr>
    <tr><td><sub><sub>Softmax</sub></sub></td><td><sub><sub>142.6166</sub></sub></td><td><sub><sub>142.6542</sub></sub></td><td><sub><sub>99.97</sub></sub></td><td><sub><sub>0.264</sub></sub></td></tr>
    <tr><td><sub><sub>CopyProbsToCPU</sub></sub></td><td><sub><sub>0.4929</sub></sub></td><td><sub><sub>0.4616</sub></sub></td><td><sub><sub>93.22</sub></sub></td><td><sub><sub>67.718</sub></sub></td></tr>
    <tr><td><sub><sub>Sampling</sub></sub></td><td><sub><sub>0.0675</sub></sub></td><td><sub><sub>0.0824</sub></sub></td><td><sub><sub>81.86</sub></sub></td><td><sub><sub>181.439</sub></sub></td></tr>
    <tr><td><b><sub><sub>End-to-end</sub></sub></b></td><td><b><sub><sub>3640.4104</sub></sub></b></td><td><b><sub><sub>3640.3191</sub></sub></b></td><td><b><sub><sub>99.99</sub></sub></b></td><td><b><sub><sub>0.025</sub></sub></b></td></tr>
    <!-- Gemma -->
    <tr>
      <td rowspan="7" style="border: 1px solid #000; padding: 4px; writing-mode: vertical-rl; transform: rotate(180deg);"><sub><sub>Gemma-2-2B-it</sub></sub></td>
      <td><sub><sub>Embedding</sub></sub></td><td><sub><sub>0.7659</sub></sub></td><td><sub><sub>0.7398</sub></sub></td><td><sub><sub>96.48</sub></sub></td><td><sub><sub>35.226</sub></sub></td>
    </tr>
    <tr><td><sub><sub>Prefill</sub></sub></td><td><sub><sub>9301.1318</sub></sub></td><td><sub><sub>9301.0589</sub></sub></td><td><sub><sub>99.99</sub></sub></td><td><sub><sub>0.008</sub></sub></td></tr>
    <tr><td><sub><sub>Decode</sub></sub></td><td><sub><sub>54.5909</sub></sub></td><td><sub><sub>54.5557</sub></sub></td><td><sub><sub>99.94</sub></sub></td><td><sub><sub>0.646</sub></sub></td></tr>
    <tr><td><sub><sub>Softmax</sub></sub></td><td><sub><sub>502.3319</sub></sub></td><td><sub><sub>502.3698</sub></sub></td><td><sub><sub>99.99</sub></sub></td><td><sub><sub>0.076</sub></sub></td></tr>
    <tr><td><sub><sub>CopyProbsToCPU</sub></sub></td><td><sub><sub>0.5570</sub></sub></td><td><sub><sub>0.5255</sub></sub></td><td><sub><sub>94.02</sub></sub></td><td><sub><sub>59.829</sub></sub></td></tr>
    <tr><td><sub><sub>Sampling</sub></sub></td><td><sub><sub>0.1698</sub></sub></td><td><sub><sub>0.1830</sub></sub></td><td><sub><sub>92.76</sub></sub></td><td><sub><sub>72.365</sub></sub></td></tr>
    <tr><td><b><sub><sub>End-to-end</sub></sub></b></td><td><b><sub><sub>9859.5473</sub></sub></b></td><td><b><sub><sub>9859.4329</sub></sub></b></td><td><b><sub><sub>99.99</sub></sub></b></td><td><b><sub><sub>0.012</sub></sub></b></td></tr>
  </tbody>
</table>


### 2. Kernel-level profiling accuracy on Pixel 8 Pro and Pixel 7:

<table style="border-collapse: collapse; width: 80%; font-size: 9px; text-align: center; border: 1px solid #000;">
  <thead>
    <tr>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;">Kernels</th>
      <th rowspan="2" style="border: 1px solid #000; padding: 4px;">Phases</th>
      <th colspan="4" style="border: 1px solid #000; padding: 4px;">Google Pixel 8 Pro</th>
      <th colspan="2" style="border: 1px solid #000; padding: 4px;">Google Pixel 7</th>
    </tr>
    <tr>
      <th style="border: 1px solid #000; padding: 4px;">Profiled latency (ms)<br><span style="font-variant: small-caps;">LM-Meter</span></th>
      <th style="border: 1px solid #000; padding: 4px;">Profiled latency (ms)<br>GT</th>
      <th style="border: 1px solid #000; padding: 4px;">α (%)</th>
      <th style="border: 1px solid #000; padding: 4px;">ε★ (μs/ms)</th>
      <th style="border: 1px solid #000; padding: 4px;">α (%)</th>
      <th style="border: 1px solid #000; padding: 4px;">ε★ (μs/ms)</th>
    </tr>
  </thead>

  <tbody>
    <!-- Prefill -->
    <tr><td>dequantize1_NT_matmul5</td><td rowspan="4" style="border: 1px solid #000; padding: 4px;">Prefill</td><td>81.1899</td><td>82.1329</td><td>98.85</td><td>11.481</td><td>98.88</td><td>11.212</td></tr>
    <tr><td>dequantize2_NT_matmul6</td><td>31.3407</td><td>31.7568</td><td>98.69</td><td>13.103</td><td>95.18</td><td>48.209</td></tr>
    <tr><td>dequantize3_NT_matmul7</td><td>330.3757</td><td>332.7218</td><td>99.29</td><td>7.051</td><td>98.87</td><td>11.328</td></tr>
    <tr><td>dequantize4_NT_matmul8</td><td>367.5603</td><td>367.0284</td><td><b>99.86 (highest)</b></td><td>1.449</td><td>99.11</td><td>8.896</td></tr>
    <!-- Decode -->
    <tr><td>dequantize1_NT_matmul10</td><td rowspan="9" style="border: 1px solid #000; padding: 4px;">Decode</td><td>0.3643</td><td>0.3737</td><td>97.46</td><td>25.391</td><td>97.19</td><td>28.145</td></tr>
    <tr><td>dequantize2_NT_matmul11</td><td>0.2062</td><td>0.2006</td><td>97.23</td><td>27.706</td><td>98.14</td><td>18.587</td></tr>
    <tr><td>dequantize3_NT_matmul12</td><td>1.3813</td><td>1.3601</td><td>98.44</td><td>15.587</td><td>98.17</td><td>18.267</td></tr>
    <tr><td>dequantize4_NT_matmul13</td><td>0.6862</td><td>0.6586</td><td>95.81</td><td>41.921</td><td>97.50</td><td>25.044</td></tr>
    <tr><td>dequantize_NT_matmul14_divide2_tir_tanh2_multiply8</td><td>18.4379</td><td>18.3619</td><td>99.59</td><td>4.147</td><td>98.13</td><td>18.705</td></tr>
    <tr><td>add_norm_prefill</td><td>0.1149</td><td>0.1059</td><td><b>91.51 (lowest)</b></td><td>84.891</td><td>93.29</td><td>67.080</td></tr>
    <tr><td>rms_norm2</td><td>0.1037</td><td>0.1092</td><td>94.93</td><td>50.641</td><td>92.65</td><td>73.531</td></tr>
    <tr><td>split2_gelu_tanh2_multiply7</td><td>0.0952</td><td>0.0939</td><td>98.62</td><td>13.727</td><td>93.75</td><td>62.517</td></tr>
    <tr><td>multiply6</td><td>0.1061</td><td>0.1005</td><td>94.35</td><td>56.546</td><td><b>90.31</b></td><td>96.934</td></tr>
    <!-- Softmax -->
    <tr><td>chunk_lse</td><td rowspan="2" style="border: 1px solid #000; padding: 4px;">Softmax</td><td>0.2718</td><td>0.2839</td><td>95.53</td><td>44.735</td><td>99.39</td><td>6.026</td></tr>
    <tr><td>softmax_with_chunked_sum</td><td>0.2376</td><td>0.2392</td><td>99.33</td><td>6.689</td><td><b>99.40</b></td><td>5.992</td></tr>
    <!-- Embedding -->
    <tr><td>dequantize_take1</td><td style="border: 1px solid #000; padding: 4px;">Embedding</td><td>0.1034</td><td>0.1097</td><td>94.26</td><td>57.429</td><td>95.73</td><td>42.676</td></tr>
  </tbody>
</table>

### 3. Kernel-level profiling accuracy on Pixel 8 Pro:



## Acknowledgement

Many thanks to these excellent open source projects:
- [MLC LLM](https://llm.mlc.ai/) 
- [tvm](https://github.com/apache/tvm)