const f64 = new Float64Array(2);
const u32 = new Uint32Array(f64.buffer, 0, 1);
const u16 = new Uint16Array(f64.buffer, 4, 3);
const u64 = new BigUint64Array(f64.buffer, 8, 1);

window.turboUUID = () => (
    f64[0] = Math.random(),
    f64[1] = Math.random()) && (
        u32[0].toString(16).padEnd(8, 0).concat("-")
            .concat(u16[0].toString(16).padEnd(4, 0)).concat("-")
            .concat(u16[1].toString(16).padEnd(4, 0)).concat("-")
            .concat(u16[2].toString(16).padEnd(4, 0)).concat("-")
            .concat(u64[0].toString(16).substring(4)).padEnd(36, 0)
    );

turboUUID.benchmark = (count = 1e6) => {
    let t0, tLen, dt;
    console.warn(`benchmark started to generation ${count} UUID strings.`);

    tLen = count;
    t0 = performance.now();
    while (tLen--) crypto.randomUUID();
    dt = performance.now() - t0;
    console.log("crypto.randomUUID:\t", dt, "ms sample:", crypto.randomUUID());
    //crypto.randomUUID: 1176.0499997138977 ms sample: 045989d4-e3b6-4ebc-99f4-4649c9c9ccea

    tLen = count;
    t0 = performance.now();
    while (tLen--) window.turboUUID();
    dt = performance.now() - t0;
    console.log("window.turboUUID:\t", dt, "ms sample:", window.turboUUID());
    //window.turboUUID: 404.78500032424927 ms sample: 853dcff4-2729-3fd6-fe00-36efc5920fe0
};

turboUUID.base = async () => {
    return WebAssembly.instantiateStreaming(fetch("uuid.wasm"), self).then(i => console.log(i) || i.instance.exports);
}
