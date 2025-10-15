# BigVec: The 128-bit Scalar Primitive You've Been Waiting For

In the realm of JavaScript, we have numbers, we have strings, and we have BigInts. But what if you need to work with 128-bit data structures as if they were scalar values? What if you could have the power of a 128-bit vector with the simplicity of a primitive?

**Behold, `BigVec`.**

`BigVec` is a novel data type for JavaScript that brings the power of 128-bit vectors to your fingertips. It's not just a class; it's a new way of thinking about data in JavaScript. It's a bridge between the world of high-level JavaScript objects and the low-level world of binary data.

## The Art of Intelligence

`BigVec` is more than just code; it's a testament to the "Art of Intelligence." It's the result of a deep understanding of JavaScript's internals and a desire to create something truly new and powerful. It's a dance between the flexibility of `BigInt` and the raw power of `ArrayBuffer`.

We didn't just want to create another library. We wanted to create a new primitive. And while `BigVec` may not be a true primitive in the eyes of the JavaScript engine, it behaves like one in your code. It's a scalar value that you can pass around, compare, and manipulate with ease.

## Features

*   **128-bit Scalar Values:** Treat 128-bit vectors as if they were single numbers.
*   **UUIDs as First-Class Citizens:** Create, manipulate, and convert UUIDs with ease.
*   **Seamless Conversion:** Convert between `BigVec`, `BigInt`, `String`, `ArrayBuffer`, and more.
*   **Typed Arrays:** Use `BigVec128Array` to work with collections of `BigVec`s with a familiar API.
*   **Performance:** `BigVec128Array` uses a single `ArrayBuffer` for memory efficiency.
*   **Debugger-Friendly:** A custom debugger hook provides a rich, explorable view of your `BigVec` data.

## Usage

```javascript
import { BigVec, BigVec128Array } from "./index.js";

// Create a BigVec from a UUID
const vec1 = BigVec.fromUUID("f81d4fae-7dec-11d0-a765-00a0c91e6bf6");

// Create a BigVec from a BigInt
const vec2 = BigVec.fromBigInt(123456789n);

// Create a random BigVec
const randomVec = BigVec.random();

// Convert to different formats
console.log("UUID:", randomVec.toUUID());
console.log("HEX:", randomVec.toHEX());
console.log("String:", randomVec.toString());
console.log("Array:", randomVec.toArray());
console.log("Buffer:", randomVec.toBuffer());

// Work with arrays of BigVecs
const arr = new BigVec128Array(5);
arr.set([
    BigVec.random(),
    BigVec.random(),
    BigVec.random(),
    BigVec.random(),
    BigVec.random(),
]);

console.log("UUID Array:", arr.toUUIDArray());
```

## The Magic: How it Works

You might be wondering, "How is this possible?" The secret lies in a beautiful hack.

`BigVec` leverages the power of JavaScript's `BigInt` to store its 128-bit value. When you create a `BigVec`, we're actually creating a `BigInt` object and then changing its prototype to `BigVec.prototype`. This gives us the ability to add our own methods to the `BigInt` object, effectively creating a new primitive type.

The real magic happens when you call `toString(16)` on a `BigVec`. Because our `BigVec` is secretly a `BigInt`, we can use `BigInt.prototype.toString.call(this, 16)` to get a 32-character hex string representation of the 128-bit value. This is the key that unlocks the door to UUIDs and other 128-bit data formats.

## A New Primitive for a New Era

`BigVec` is more than just a library; it's a new way of thinking about data in JavaScript. It's a tool for building the next generation of applications, from high-performance databases to decentralized identity systems.

We invite you to join us on this journey. Explore the code, play with the examples, and let your imagination run wild. The future of data in JavaScript is here, and it's called `BigVec`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.