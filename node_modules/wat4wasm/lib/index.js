#!/usr/bin/env node

import fs from "fs";
import wat4beauty from "./wat4beauty.js"

import { processCLI } from "./cli.js";
import clean from "./clean.js";

import ASYNC from "./processors/async.js"
import DATA from "./processors/data.js"
import IMPORT from "./processors/import.js"
import INCLUDE from "./processors/include.js"
import NEW from "./processors/new.js"
import REF_EXTERN from "./processors/ref_extern.js"
import REF_FUNC from "./processors/ref_func.js"
import REPLACE_ALL from "./processors/replace_all.js"
import START from "./processors/start.js"
import STRING from "./processors/string.js"
import TEXT from "./processors/text.js"
import W4W from "./processors/wat4wasm.js"

const processors = [
    W4W,
    TEXT,
    ASYNC,
    DATA,
    IMPORT,
    INCLUDE,
    NEW,
    REF_EXTERN,
    REF_FUNC,
    START,
    STRING,
    REPLACE_ALL,
    REF_EXTERN,
    DATA,
];


processCLI(async (wat4, config) => {
    let wat2, f, i = -1, llen, m = -1, c = 0, ci = 0;

    wat2 = await config.APPLY(wat4, W4W);

    while (f = processors[++i]) {
        wat4 = await f(wat2, W4W).toString();

        const input = wat2;
        const output = wat4;
        const inLines = input.split("\n").map(l => l.trim()).filter(Boolean);
        const outLines = output.split("\n").map(l => l.trim()).filter(Boolean);

        let startCommon = 0;
        while (
            startCommon < inLines.length &&
            startCommon < outLines.length &&
            inLines[startCommon] === outLines[startCommon]
        ) { startCommon++; }

        let endCommon = 0;
        while (
            endCommon < inLines.length - startCommon &&
            endCommon < outLines.length - startCommon &&
            inLines[inLines.length - 1 - endCommon] === outLines[outLines.length - 1 - endCommon]
        ) { endCommon++; }

        const commonLines = startCommon + endCommon;
        const removedLines = inLines.length - commonLines;
        const addedLines = outLines.length - commonLines;
        const netChange = outLines.length - inLines.length;

        const stat = [
            `\x1b[32m+${addedLines}\x1b[0m`.padStart(16, " "),
            `\x1b[34m-${removedLines}\x1b[0m`.padStart(16, " "),
            `\x1b[${netChange && 36 || 33}m\u0394\x1b[0m`.padStart(14, " "),
            `\x1b[${netChange && 36 || 33}m${netChange}\x1b[0m`.padStart(14, " "),
            `  byte(\u03B4) :`,
            `\x1b[33m${wat2.length}\x1b[0m`.padStart(16, " "),
            `-->`,
            `\x1b[33m${wat4.length}\x1b[0m`,
        ];

        if (wat2 !== wat4) {
            c++;
            wat2 = wat4;
            console.log(`👀 ƒ(  ${f.name.padEnd(12, " ")} )`.padStart(12, " "), ...stat);
        }

        if (!processors[i + 1]) {
            if (c) { i = -1; c = 0; }
            else { console.log("☘️  untouched raw \x1b[32m-->\x1b[0m finalizing..") }
        }
    }

    wat2 = clean(wat2, config);
    wat2 = wat4beauty(wat2, "  ");
    wat2 = await config.APPLY(wat2);

    return wat2;
});