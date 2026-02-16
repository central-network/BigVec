
import ChainBuilder, {Operation} from "./chain.mjs";

/**
 * Defines a block of operations that are embedded in the main chain but skipped during sequential execution.
 * They are effectively a "sub-procedure" that can be called by branching to the returned operation.
 * 
 * This solves the relocation problem: Ops are resolved within the main address space.
 * 
 * @param {ChainBuilder} mainChain 
 * @param {Function} builderFn 
 * @returns {Operation} The container operation (ptr points to start of block).
 */
export function defineInnerChain(mainChain, builderFn) {
    const innerChain = new ChainBuilder(mainChain);
    
    // reset array to avoid side-effects if any?
    // ChainBuilder constructor with mainChain copies state but starts with empty ops. 
    
    builderFn(innerChain);
    
    // Calculate total size required for the block
    let innerSize = 0;
    innerChain.ops.forEach(op => {
        // Op structure in byte stream: [prev(4), len(4), func(4)] + payload
        op.innerOffset = innerSize;
        innerSize += 12 + op.size; 
    });
    
    // Create the Container Op in the main chain.
    // funcIndex = 0 means the interpreter will NOT call it.
    // It will just read 'len' (which is the loop header logic, typically offset 4) and skip.
    // Wait, typical op:
    // offset 0: prev
    // offset 4: len (header+payload)
    // offset 8: func
    // If func is 0, interpreter loop does:
    // ptr += len.
    // So if we make this container op cover all inner ops, the loop jumps over them.
    
    const containerOp = mainChain.addOp('block', innerSize, 0, (view, offset, container, resolveFn) => {
        // `offset` here is the start of the payload of the container op.
        // `resolveFn` resolves main chain ops.
        
        const baseAddr = offset; // This is where the Inner Chain effectively starts.
        
        // Custom resolver that handles "local" inner ops and falls back to main resolver
        const innerResolveFn = (targetOp) => {
            if (targetOp && typeof targetOp.innerOffset === 'number') {
                return baseAddr + targetOp.innerOffset;
            }
            return resolveFn(targetOp);
        };
        
        const Buffer = mainChain.$self.Buffer || global.Buffer; // Polyfill check if needed

        innerChain.ops.forEach(innerOp => {
            const currentAbsOffset = baseAddr + innerOp.innerOffset;
            
            // 1. Write Headers logic (mimicking ChainBuilder.resolve)
            // prevPtr (ignored by VM logic usually, but let's be clean)
            view.setInt32(currentAbsOffset + 0, 0, true); 
            // length
            view.setInt32(currentAbsOffset + 4, 12 + innerOp.size, true);
            // funcIndex
            view.setInt32(currentAbsOffset + 8, innerOp.funcIndex, true);
            
            // 2. Write Payload
            const payloadOffset = currentAbsOffset + 12;
            if (innerOp.writePayloadFn) {
                // Pass our relocating resolver!
                innerOp.writePayloadFn(view, payloadOffset, innerOp, innerResolveFn);
            }
            
            // 3. Handle Data/Buffer copy (critical for copyFrom)
            // Logic copied/adapted from process.js/chain.js
            if ("buffer" in innerOp || "data" in innerOp) { 
                let data = Buffer.from(innerOp.data || innerOp.buffer.data);
                let dataLength = data.byteLength;
                
                // For 'copyFrom' ops, the writePayloadFn (copyInto) writes:
                // [target, offset, len, begin]
                // offset (dest) is at header+4.
                
                // We need to read what was just written to know where to copy the data *to*.
                // The writePayloadFn wrote relative offsets (via innerResolveFn)? 
                // No, innerResolveFn returns ABSOLUTE addresses (baseAddr + inner).
                // So the parameters in the view are absolute addresses.
                
                // The standard chain.js logic reads: view.getInt32(op.offset + 16)
                // op.offset + 16 = dataOffset + 4.
                // dataOffset for us is payloadOffset.
                
                let viewOffset = view.getInt32(payloadOffset + 4, true); 
                // This 'viewOffset' is the ABSOLUTE address in the buffer where data goes.
                // But `view` is a DataView on the whole buffer. 
                // So we can write directly.
                
                // Wait, Buffer.copy logic in chain.js:
                // while(copyLength--) view.setUint8(viewOffset++, ...)
                
                // We rely on the fact that `copyInto` op set the destination correctly.
                // innerResolveFn(op) -> baseAddr + innerOffset.
                // header(copyInto) -> writes (baseAddr + innerOffset + 16) into param 2.
                // So viewOffset is correct.
                
                // Source data offset (from the asset buffer)
                let dataOffset = view.getInt32(payloadOffset + 12, true); // param 4 usually?
                // chain.js: view.getInt32(op.offset + 24) -> which is payload+12. Correct ("begin").
                
                let viewLength = view.getInt32(payloadOffset + 8, true); // len
                
                let copyLength = Math.min(dataLength, viewLength);

                while (copyLength--) {
                    view.setUint8(viewOffset++, data.readUint8(dataOffset++));
                }
            }
        });
    });
    
    // We return the container. 
    // Usage: bindWasmFunction(..., container) -> container.dataOffset is the address.
    return containerOp;
}

// Re-export old name if needed or just use new one
export const createInnerChain = defineInnerChain; 


/**
 * Creates an async callback operation structure.
 * 
 * @param {ChainBuilder} mainChain - The main chain builder.
 * @param {Object} options
 * @param {number} options.resultCount - Number of externrefs the callback will produce (arg1, arg2...)
 * @param {Operation|Uint8Array} options.innerChain - The inner chain to execute (as an Op or raw bytes)
 * @returns {Operation} The allocated callback structure op.
 */
export function createAsyncCallback(mainChain, { resultCount = 1, innerChain }) {
    
   
    // 2. Prepare the inner chain data
    let innerChainOp = innerChain;
    
    // 3. Allocate the Callback Header Struct
    // Structure: [ count, start_index, chain_ptr ]
    return mainChain.addOp('apply', 32, 0, (view, offset, callbackOp) => {
        callbackOp.setHeader(3, callbackOp.tableIdx);
        callbackOp.setHeader(4, 2);
    }, resultCount);
}

/**
 * Creates a bound WASM callback function.
 */
export function bindWasmFunction(chain, funcIndex, args = []) {
    const fnBind = chain.resolve_path("$self.Function.bind");
    const fnApply = chain.resolve_path("$self.Reflect.apply");

    const argsArrayOp = chain.wasm_array();
    const applyArgsOp = chain.wasm_array();

    const tableIdx_call = argsArrayOp.tableIdx;
    const tableIdx_bind = applyArgsOp.tableIdx;

    args.forEach((arg,i) => {
        const set = chain.wasm_set_eii(
            tableIdx_call, i, +arg
        );

        if (arg instanceof Operation) {
            console.log(arg)
            chain.copy(arg, set, 8, 4, 24);
        }
    });

    const set_apply_bind_arg0_func = chain.wasm_set_eie(tableIdx_bind, 0, 0); 
    const set_apply_bind_arg1_this = chain.wasm_set_eif(tableIdx_bind, 1, funcIndex); 
    const set_apply_bind_arg2_args = chain.wasm_set_eie(tableIdx_bind, 2, tableIdx_call); 

    chain.copy(fnBind, set_apply_bind_arg0_func, 8, 4); 

    return chain.apply(fnApply, null, applyArgsOp);
}
