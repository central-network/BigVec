
import { self, kDebug } from "./Global.mjs";
import { compiler } from "./Compiler.mjs";
import fs from "fs";
import { Funcref } from "./Funcref.mjs";

const funcref = new Funcref();

console.log(funcref.toString());

process.exit();

console.log(self[kDebug]());

// WCL Test Script
console.log("Starting WCL Compilation...");

// 1. Array Allocation
const arr = new self.Array();
console.log("Allocated Array:", arr);

// 2. Push Value (Method Chaining)
// const pushResult = arr.push(42);
// console.log("Push Result:", pushResult);

// 3. String Creation (via Global)
const str = new self.String("Hello WCL");
console.log("Created String:", str);

// 4. Console Log (Global Call)
// This will triggered:
// 1. Get(self, "console") -> Op Console
// 2. Get(Op Console, "log") -> Op Log
// 3. Call(Op Log, Op Console, [str])
self.console.log(str); 
self.console.log(arr);

// 5. Nested object creation and access
// const obj = new self.Object();
// obj.nested = new self.Object();
// obj.nested.value = 123;
// self.console.log(obj.nested.value);

// 5. Compile
console.log("Compiling headers...");

// DEBUG: Check for duplicate ops
const ops = compiler.builder.ops;
const ids = new Set();
ops.forEach((op, index) => {
    if (ids.has(op)) {
        console.error(`DUPLICATE OP FOUND at index ${index}:`, op.id, op.type);
    }
    ids.add(op);
});
console.log("Total Ops:", ops.length);

const hex = compiler.compile(); // This returns hex string or buffer

// chain.mjs usually writes file internally via 'writeFile' if using chain.writeFile 
// But Compiler.compile() currently just returns hex/buffer from builder.resolve/getHex.
// Let's manually write for now or use builder's write.
compiler.builder.writeFile("wcl_output.wasm");

console.log("WCL Compilation Finished. wcl_output.wasm generated.");
