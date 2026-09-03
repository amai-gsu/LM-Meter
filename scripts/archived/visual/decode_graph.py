#!/usr/bin/env python3
"""
decode_graph.py  –  compact, data-flow Graphviz for TVM @R.function decode()

Usage
-----
    python3 decode_graph.py /path/to/debug-final.py

Creates  decode_graph.pdf  in the same directory.

What you’ll see
---------------
• green ellipses  : fused kernels  (cls.gemma2_q4f16_…)
• khaki ellipse   : KV-cache attention call
• blue boxes      : activations  (alloc*/lv*, input_embed)
• yellow boxes    : weights/scales ( …_weight… / …_scale… )
• tensor boxes sit *between* producer → consumer kernels so the arrow text
  is literally the tensor name you asked for.
"""
import re, sys, pathlib
from graphviz import Digraph

if len(sys.argv) != 2:
    print("Usage: python3 decode_graph.py <debug-final.py>")
    sys.exit(1)

src_path = pathlib.Path(sys.argv[1])
src      = src_path.read_text()

# ─── slice ONLY the def decode() body ─────────────────────────────
start = src.find("def decode")                         # ← new start anchor
end   = src.find("\n    return", start)                # first return indent
decode_txt = src[start:end] if (start != -1 and end != -1) else src

# ─── Graph init ───────────────────────────────────────────────────
gv = Digraph(comment="decode_graph", format="pdf")
gv.attr(rankdir="TB", splines="spline", overlap="false",
        nodesep="0.15", ranksep="0.25")

# ─── regex helpers ────────────────────────────────────────────────
KERNEL_RE = re.compile(r"cls\.(gemma2_q4f16_[^(]+)\((.*?)\)")
KV_RE     = re.compile(r"vm\.builtin\.attention_kv_cache_attention_with_fused_qkv")
TENSOR_RE = re.compile(r"\b(alloc\d+|lv\d+|input_embed|paged_kv_cache|"
                       r"\w+_weight\d*|\w+_scale\d*)\b")

# ─── bookkeeping ─────────────────────────────────────────────────
kernel_idx   = 0
tensor_node  = {}        # tensor → node-id
tensor_prod  = {}        # tensor → producing kernel node

def ensure_tensor(t):
    if t in tensor_node:
        return tensor_node[t]
    colour = ("lightyellow" if ("_weight" in t or "_scale" in t
                                or t == "paged_kv_cache")
              else "lightskyblue")
    nid = f"T_{t}"
    gv.node(nid, t, shape="box", style="filled",
            fillcolor=colour, fontsize="10")
    tensor_node[t] = nid
    return nid

def new_kernel(label, fill):
    global kernel_idx
    knode = f"K{kernel_idx}"
    kernel_idx += 1
    gv.node(knode, label, shape="ellipse", style="filled",
            fillcolor=fill, fontsize="10")
    return knode

# ─── main loop over decode() lines ───────────────────────────────
for line in decode_txt.splitlines():
    line = line.strip()

    # fused gemma2 kernels
    km = KERNEL_RE.search(line)
    if km:
        label, arglist = km.group(1), km.group(2)
        tensors = TENSOR_RE.findall(arglist)
        kn = new_kernel(label, "palegreen")

        for t in tensors:
            tn = ensure_tensor(t)
            if t in tensor_prod:
                gv.edge(tensor_prod[t], tn)  # producer → tensor
            gv.edge(tn, kn)                  # tensor → consumer

        outs = [t for t in tensors if t.startswith(("alloc", "lv"))
                and t not in tensor_prod] or [
                t for t in reversed(tensors) if t.startswith(("alloc", "lv"))][:1]
        for t in outs:
            tensor_prod[t] = kn
        continue

    # KV-cache attention
    if KV_RE.search(line):
        tensors = TENSOR_RE.findall(line)
        kn = new_kernel("KV-cache attention", "khaki")

        for t in tensors:
            tn = ensure_tensor(t)
            if t in tensor_prod:
                gv.edge(tensor_prod[t], tn)
            gv.edge(tn, kn)

        # mark last alloc* as output
        for t in reversed(tensors):
            if t.startswith("alloc"):
                tensor_prod[t] = kn
                break
        continue

# ─── render ──────────────────────────────────────────────────────
out = src_path.with_suffix("").name + "_graph"
gv.render(out, cleanup=False)
print("✓ wrote", out + ".pdf")
