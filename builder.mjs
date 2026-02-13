import fs from "fs";
import ChainBuilder from "./chain.mjs";


const chain = new ChainBuilder();
const $self = chain.$self;

const STRING_DATA = new TextEncoder().encode("gemini 💕 özgür")
const $decoder = new chain.$self.TextDecoder();
const $textBuffer = chain.copyFrom( STRING_DATA );
const $decodeFunc = chain.$self.TextDecoder.prototype.decode; 
const $decodedString = $decodeFunc.call($decoder, $textBuffer);
$self.console.log($decodedString);


const MODULE_DATA = fs.readFileSync("test.wasm");
const $wasmModuleSource = chain.copyFrom( MODULE_DATA );
const $promisedCompile = chain.$self.WebAssembly.compile($wasmModuleSource);
$self.console.log($promisedCompile);

chain.writeFile("h.wasm");

console.log("Builder finished. h.wasm generated.");
