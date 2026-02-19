export default (op) => {
    const view = new Uint32Array(op.buffer.buffer);
    const array = Array.from(view);
    const output = new Array();

    let tlength = 0;

    for(const HEADER_NAME in op.HEADERS) {
        const HEADER_INDEX = op.HEADERS[HEADER_NAME];
        const HEADER_OFFSET = op.BYTES_PER_HEADER * HEADER_INDEX; 
        const HEADER_VALUE = op.getHeader(HEADER_INDEX);

        output.push({
            ["(header)"]: HEADER_NAME, 
            ["(offset)"]: HEADER_OFFSET,
            ["(uint32)"]: HEADER_VALUE
        });

        tlength = Math.max(tlength, HEADER_NAME.length);
    }
    tlength += (output.length * 6);

    
    let nwidth = tlength;
    let fwidth = tlength;
    let swidth = tlength;

    nwidth -= `| this : ${op.constructor.name}`.length;
    nwidth -= 2;
    
    swidth -= `| size : ${op.buffer.byteLength}`.length;
    swidth += 1;
    
    fwidth -= `func: { name: "${op.CALL_INDIRECT_$NAME}", index: ${op.CALL_INDIRECT_INDEX} }`.length;
    fwidth -= 2;

    console.table(output);
    console.log("⎧".concat("‾".repeat(tlength).concat("⎫")))
    console.log("⏐ this :", op, "⏐".padStart(nwidth, " "));
    console.log("⏐ data :", op.buffer);
    console.log("⏐ size :", op.buffer.byteLength, "⏐".padStart(swidth, " "));
    console.log("⏐ func :", {
        name: op.CALL_INDIRECT_$NAME, 
        index: op.CALL_INDIRECT_INDEX
    }, "⏐".padStart(fwidth, " "));
    console.log("⎩".concat("_".repeat(tlength).concat("⎭")), "\n")
}