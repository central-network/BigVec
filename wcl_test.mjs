
import { self, kDebug } from "./Global.mjs";
import { compiler } from "./Compiler.mjs";
import chain_module from "./chain_module.mjs"; // ensure init

// User-land test
// Access property
const consoleLog = self.console.log; // Resolves self(1) -> console(4) -> log(5)

// Call it
consoleLog("Hello"); 
// 1. Alloc "Hello" (index 6, mocked)
// 2. Alloc Array [6] (index 7)
// 3. Apply log(5), this=console(4), args=7 -> result 8

// Another call
// self.console.log("World");

// Compile
const modBuilder = compiler.compile();
const buffer = modBuilder.compile("chain.wasm", true).output;

console.log("WASM Compiled!");
