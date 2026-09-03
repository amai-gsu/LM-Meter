"""This is a customized pass that duplicates a target kernel and inject the duplication right after the original kernel."""

import tvm
from tvm import relax, IRModule

# ---- Decode ---
# fused_dequantize1_NT_matmul10
# fused_dequantize2_NT_matmul11
# fused_dequantize3_NT_matmul12
# fused_dequantize4_NT_matmul13
# fused_dequantize_fused_NT_matmul14_divide2_tir_tanh2_multiply8
# fuse_add_norm_prefill
# rms_norm2
# fused_split2_gelu_tanh2_multiply7
# multiply6
# ---- Softmax ---
# chunk_lse
# softmax_with_chunked_sum
# ---- Embedding ---
# fused_dequantize_take1
# ---- Prefill
# fused_dequantize1_NT_matmul5
# fused_dequantize2_NT_matmul6
# fused_dequantize3_NT_matmul7
# fused_dequantize4_NT_matmul8
# fused_split1_gelu_tanh1_multiply4
# rms_norm1
# multiply3

TARGET_KERNEL = "multiply6" # update "model_lib" in mlc-package-config.json
NUM_DUPS    = 1000

@tvm.transform.module_pass(opt_level=0, name="InjectExtraKernelCall")
def InjectExtraKernelCall(mod: IRModule, _pc):
    """Duplicate TARGET_KERNEL NUM_DUPS times immediately after its first call
    inside the model’s entry function."""

    # ------------------------------------------------------------------
    # 1. Determine which Relax function to patch
    # ------------------------------------------------------------------
    if TARGET_KERNEL == "fused_dequantize_take1":
        entry_names = ["embed"]
        err_msg = "embed not found in IRModule"
    elif TARGET_KERNEL in ("softmax_with_chunked_sum", 
                           "chunk_lse"):
        entry_names = ["softmax_with_temperature"]
        err_msg = "softmax_with_temperature not found in IRModule"
    elif TARGET_KERNEL in ("fused_dequantize1_NT_matmul5", 
                           "fused_dequantize2_NT_matmul6",
                           "fused_dequantize3_NT_matmul7",
                           "fused_dequantize4_NT_matmul8",
                           "fused_split1_gelu_tanh1_multiply4",
                           "rms_norm1",
                           "multiply3"):
        entry_names = ["prefill"]
        err_msg = "prefill not found in IRModule"
    else:
        entry_names = ["decode"]
        err_msg = "decode not found in IRModule"

    # locate the GlobalVar
    for fn_name in entry_names:
        try:
            decode_gv = mod.get_global_var(fn_name)
            break
        except KeyError:
            continue
    else:
        raise RuntimeError(err_msg)

    func: relax.Function = mod[decode_gv]
    tir_call_op = tvm.ir.Op.get("relax.call_tir")
    orig_gv = mod.get_global_var(TARGET_KERNEL)

    # walk the SeqExpr blocks and insert a second call immediately after the first
    assert isinstance(func.body, relax.SeqExpr)
    new_blocks = []
    injected = False

    for block in func.body.blocks:
        # Copy non-dataflow blocks untouched
        if not isinstance(block, relax.DataflowBlock):
            new_blocks.append(block)
            continue

        new_bindings = []
        for binding in block.bindings:
            new_bindings.append(binding)

            if (
                not injected 
                and isinstance(binding, relax.VarBinding)
                and isinstance(binding.value, relax.Call)
            ):
                call = binding.value
                if (
                        call.op == tir_call_op                      # is call_tir
                        and isinstance(call.args[0], relax.GlobalVar)
                        and call.args[0].same_as(orig_gv)           # kernel matches
                    ):
                    # clone the original call (same args / attrs / sinfo)
                    for i in range(NUM_DUPS):
                        dup_call = relax.Call(
                            call.op,
                            call.args,
                            call.attrs,
                            call.sinfo_args
                        )
                        dup_var  = relax.Var(
                            f"{binding.var.name_hint}_dup{i}",
                            call.sinfo_args[0]
                        )
                        new_bindings.append(relax.VarBinding(dup_var, dup_call))
                    # extra_call = relax.Call(call.op, call.args,
                    #                         call.attrs, call.sinfo_args)
                    # print("extra_call: ", extra_call)
                    # tmp_var = relax.Var(f"{binding.var.name_hint}_dup", call.sinfo_args[0])
                    # new_bindings.append(relax.VarBinding(tmp_var, extra_call))
                    injected = True

        new_blocks.append(relax.DataflowBlock(new_bindings))

    if not injected:
        raise RuntimeError(f"No call to {TARGET_KERNEL} found in {decode_gv.name_hint}")

    mod[decode_gv] = relax.Function(
        func.params,
        relax.SeqExpr(new_blocks, func.body.body),
        ret_struct_info=func.ret_struct_info,
        is_pure=func.is_pure,
        attrs=func.attrs,
        span=func.span,
    )
    return mod



