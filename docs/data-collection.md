# How to Use LM-Meter to Collect Latency Data

Please use the script **`scripts/data_relavant/option2_stream_logcats_and_pull_traces.sh`** to collect either **phase-level** or **kernel-level** latency data from your target Android device.

👉 Note: When LM-Meter runs with **kernel-level profiling**, it will automatically capture both **phase-level** and **kernel-level** latency.

---

## When and How to Run `option2_stream_logcats_and_pull_traces.sh`

1. Run `option2_stream_logcats_and_pull_traces.sh` on your **host machine**.  
2. Launch the app on your **Android device** and start the selected model.  

This workflow collects both:  
- **Runtime logs** (`tvm_mlc.log`)  
- **Structured trace JSONs** (`trace_*.json`)  
during on-device LLM inference (via MLC/TVM runtime).

```              
                 ┌────────────────────────┐
                 │      Android Device    │
                 │                        │
                 │  • logcat (TVM/MLC)    │
                 │  • trace_*.json        │
                 └──────────┬─────────────┘
                            │ adb
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼─────────┐                  ┌──────────▼─────────┐
│  Host Machine   │                  │  Host Machine      │
│  (Log Output)   │                  │  (Trace Files)     │
│                 │                  │                    │
│  tvm_mlc.log    │                  │  traces/           │
│                 │                  │  └─ trace_*.json   │
└─────────────────┘                  └────────────────────┘
```

---

## 1. What the Script Does

- **Removes old traces** on the device (`trace_*.json`).
- **Clears logcat buffers** for a clean start.
- **Streams runtime logs** with tags `TVM_RUNTIME`, `MLC_Profile`, `MLC_EVENT` →  
  saved as `tvm_mlc.log` on the host.
- **Pulls structured traces** (`trace_*.json`) from the device →  
  stored under `.../option2_<timestamp>/traces/`.
- **Organizes all outputs** under a timestamped experiment folder.

---

## 2. JSON Trace Files

Each `trace_*.json` contains a list of **trace events** (Chrome/Perfetto format).

### Standard Fields
- **`name`** → event name, e.g., `"prefill"`, `"decode"`, kernel name.  
- **`ph`** → event type (*phase*):  
  - `"B"` = begin  
  - `"E"` = end  
  - `"X"` = complete  
  - `"i"` = instant  
- **`ts`** → timestamp (microseconds since boot).  
- **`pid`** → process ID on device.  
- **`tid`** → thread ID (for parallel events).  
- **Custom fields** → vary by instrumentation, e.g., kernel duration, number of tokens, memory usage, etc.

### Example
```json
[
  {
    "name": "request added to engine (0)",
    "ph": "i",
    "ts": 1750274382114019,
    "pid": 1,
    "tid": "768885e9-1458-440a-95a3"
  },
  {
    "name": "decode_kernel",
    "ph": "X",
    "ts": 1750274383114019,
    "dur": 5234,
    "pid": 1,
    "tid": 12,
    "args": {
      "tokens": 128,
      "latency_ms": 5.23
    }
  }
]
```
## Next Steps

After collecting the logs and traces:
- Proceed with post-processing using the tutorial: [docs/logcat-post-processing.md](logcat-post-processing.md)
- This will guide you through analyzing phase-level and kernel-level latencies in detail.