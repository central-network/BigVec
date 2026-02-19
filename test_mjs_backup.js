
import { self, kDebug } from "./Global.mjs";

import chain_module, {
    ChainQueue,
    GrowTableChainOperation,
    NewArrayChainOperation,
    CopyMemoryChainOperation,
    SetIntegerAtChainOperation,
    SetBytesFromChainOperation,
    ApplyChainOperation,
} from "./chain_module.mjs";

const chain_op_queue = new ChainQueue();

const grow_op = GrowTableChainOperation.from(6, 0);
chain_op_queue.add(grow_op);
grow_op.dump;

const array_of = NewArrayChainOperation.from(0);
chain_op_queue.add(array_of);
array_of.dump;

const setni_op = SetBytesFromChainOperation.from(
    10,
    0,
    16,
    0,
)
chain_op_queue.add(setni_op).dump;

chain_op_queue.add(SetIntegerAtChainOperation.from(10, 0, "özgür".codePointAt(0)))
chain_op_queue.add(SetIntegerAtChainOperation.from(10, 1, "özgür".codePointAt(1)))
chain_op_queue.add(SetIntegerAtChainOperation.from(10, 2, "özgür".codePointAt(2)))
chain_op_queue.add(SetIntegerAtChainOperation.from(10, 3, "özgür".codePointAt(3)))
chain_op_queue.add(SetIntegerAtChainOperation.from(10, 4, "özgür".codePointAt(4)))

const copy_op = CopyMemoryChainOperation.from(
    128,
    (
        16 +
        GrowTableChainOperation.OFFSET.RESULT_FIRST_EXTERN_INDEX
    ),
    4
);

chain_op_queue.add(copy_op);
copy_op.dump;


const strf_op = ApplyChainOperation.from(
    2,
    0,
    10,
    10
);
chain_op_queue.add(strf_op).dump;

chain_module(
    chain_op_queue.buffer
).compile("chain.wasm");