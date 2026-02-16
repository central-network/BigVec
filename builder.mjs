import fs from "fs";
import ChainBuilder from "./chain.mjs";
import self, {kSchemaNode, kSchemaType, kSchemaName, kSchemaPath} from "./Window.mjs";

console.log(1, self.Worker.prototype.terminate[kSchemaPath]);
console.log(2, self.Worker.prototype.terminate[kSchemaName]);
console.log(3, self.Worker.prototype.terminate[kSchemaType]);

const a = () => {
    const chain = new ChainBuilder();
    const self = chain.$self;
    
    const STRING_DATA = new TextEncoder().encode("gemini 💕 özgür")
    const $decoder = new self.TextDecoder();
    const $textBuffer = chain.copyFrom( STRING_DATA );
    const $decodeFunc = self.TextDecoder.prototype.decode; 
    const $decodedString = $decodeFunc.call($decoder, $textBuffer);
    self.console.log($decodedString);
    
    let $ref, $tbl, $imports = chain.wasm_array();
    $tbl = chain.wasm_array(); //$externref
    self.Array.prototype.push.call($imports, $tbl);
    self.Array.prototype.push.call($tbl, self.null);
    $ref = chain.resolve_path("self");
    self.Array.prototype.push.call($tbl, $ref);
    
    $ref = chain.resolve_path("self.navigator");
    self.Array.prototype.push.call($tbl, $ref);
    
    const bnd = self.console.log.bind(null, 123, "abc");
    
    const promise = self.Promise.withResolvers();
    const resolve = promise['resolve'];
    
    self.console.log(promise);
    self.console.log(resolve);
    
    
    
    chain.writeFile("h.wasm");
    
    console.log("Builder finished. h.wasm generated.");
}
