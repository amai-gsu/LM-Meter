#!/usr/bin/env python3
"""
plot_batch_decode.py  ────────────────────────────────────────────

Generate a Graphviz PDF that shows kernel‑launch sequence and the
weights/scales they consume for TVM's batch_decode function.

NEW: pass an optional max_layer (0‑indexed) so you can clip the graph to
just the first *n + 1* layers.  For example:

    python3 plot_batch_decode.py debug-final.py          # all layers
    python3 plot_batch_decode.py debug-final.py 1        # only layers 0 & 1

Requires:  pip install graphviz   and  brew/apt install graphviz.
"""

import re, sys, pathlib
from graphviz import Digraph

# ───────────────────────────── CLI & constants ────────────────────────────
if len(sys.argv) < 2:
    print("Usage: python plot_batch_decode.py <debug-final.py> [max_layer]")
    sys.exit(1)

SRC_PATH  = pathlib.Path(sys.argv[1])
MAX_LAYER = int(sys.argv[2]) if len(sys.argv) > 2 else None  # None ⇒ no limit

SRC       = SRC_PATH.read_text()
OUT_DOT   = SRC_PATH.with_suffix("").name + ("_clip" if MAX_LAYER is not None else "")

GV = Digraph(comment=OUT_DOT, format="pdf")
GV.attr(rankdir="LR", splines="spline")

# ───────────────────────────── regex helpers  ─────────────────────────────
CALL_RE  = re.compile(r"cls\.gemma2_[^(]+\((.*?)\)")
PKD_RE   = re.compile(r"R\.call_packed\(\"(vm\.builtin\.[^\"]+?)\", (.*?)[,)]")
WS_RE    = re.compile(r"\s+")
LAYER_RE = re.compile(r"model_layers_(\d+)_")

# ───────────────────────────── graph storage  ─────────────────────────────
seen_vars, op_idx = set(), 0
prev_op           = None
layer_subgraphs   = {}

# helpers ------------------------------------------------------------------

def add_var(var, layer_id=None):
    if var in seen_vars:  # already have node
        return
    seen_vars.add(var)
    style = "filled" if var.endswith(("_weight4", "_scale4")) else ""
    color = "lightyellow" if var.endswith("_weight4") else ("lightcyan" if var.endswith("_scale4") else "white")
    GV.node(var, var, shape="box", style=style, fillcolor=color)
    if layer_id is not None:
        layer_subgraphs.setdefault(layer_id, []).append(var)


def add_op(label, args, layer_id=None):
    global op_idx
    name = f"op{op_idx}"; op_idx += 1
    GV.node(name, WS_RE.sub(" ", label), shape="ellipse", style="filled", fillcolor="lightgrey")
    if layer_id is not None:
        layer_subgraphs.setdefault(layer_id, []).append(name)
    for v in args:
        GV.edge(v, name)
    return name


def seq_edge(curr):
    global prev_op
    if prev_op:
        GV.edge(prev_op, curr, style="dashed", color="grey")
    prev_op = curr

# ─────────────────────────────   scan lines   ─────────────────────────────
for line in SRC.splitlines():
    # 1. Generated helper kernels (gemma2_…)
    m = CALL_RE.search(line)
    if m:
        args = [v.strip() for v in m.group(1).split(',')]
        layer_match = LAYER_RE.search(line)
        layer_id    = int(layer_match.group(1)) if layer_match else None

        # Skip if layer limit specified & this op is beyond it
        if MAX_LAYER is not None and layer_id is not None and layer_id > MAX_LAYER:
            continue

        for v in args:
            add_var(v, layer_id)
        op = add_op(m.group(0).split('(')[0], args, layer_id)
        seq_edge(op)
        continue

    # 2. Built‑in packed kernels
    m = PKD_RE.search(line)
    if m:
        builtin = m.group(1)
        raw_args= [v.strip() for v in m.group(2).split(',')]
        # heuristic: looks like a tensor variable name
        args = [v for v in raw_args if re.match(r"\w+(?:_\w+)*\d+$", v)]
        # Try to infer layer id from first arg, if any
        layer_id = None
        if args:
            lm = LAYER_RE.search(args[0])
            if lm:
                layer_id = int(lm.group(1))
        if MAX_LAYER is not None and layer_id is not None and layer_id > MAX_LAYER:
            continue
        for v in args: add_var(v, layer_id)
        op = add_op(builtin, args, layer_id)
        seq_edge(op)

# ─────────────────────── optional cluster draw  ───────────────────────────
for lid, nodes in layer_subgraphs.items():
    if MAX_LAYER is not None and lid > MAX_LAYER:
        continue
    with GV.subgraph(name=f"cluster_{lid}") as c:
        c.attr(label=f"Layer {lid}", style="dotted")
        for n in nodes:
            c.node(n)

# ───────────────────────────── render & done  ─────────────────────────────
GV.render(OUT_DOT, cleanup=False)
print(f"✓ wrote {OUT_DOT}.pdf  (max_layer={MAX_LAYER})")
