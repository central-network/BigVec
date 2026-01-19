const page = 160;
const memories = {
    i8x16a: (page / 16) * 65536,
    i8x16b: (page / 16) * 65536,
    i16x8a: (page / 8) * 65536,
    i32x4a: (page / 4) * 65536,
    i64x2a: (page / 2) * 65536,
};

let size = page * 65536;
const offsets = {
    i64x2a: (size -= memories.i64x2a),
    i32x4a: (size -= memories.i32x4a),
    i16x8a: (size -= memories.i16x8a),
    i8x16b: (size -= memories.i8x16b),
    i8x16a: (size -= memories.i8x16a),
};

export default function align(wat) {

    wat = wat.replaceAll(`{{PAGE_COUNT}}`, page);

    Array.from(wat.matchAll(/\smemory\=(.[^\s]*)\s+offset\=(\d+)\s/g)).sort((a, b) => b[0].length - a[0].length).forEach(([keyword, label, offset = 0]) => {
        const start = (+offset + offsets[label]).toString(16).padStart(8, 0);;
        wat = wat.replaceAll(keyword, ` offset=0x${start} (; ${label} + ${offset} ;) `)
    });

    return wat;
}