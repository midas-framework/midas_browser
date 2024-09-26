// esm syntax not supported from node
// import { rollup } from 'https://unpkg.com/@rollup/browser/dist/es/rollup.browser.js';
// rollup browser uses wasm and it's import path is messed up by bundling.
// import { rollup } from '@rollup/browser';

import { Ok, Error } from "./gleam.mjs";


export async function bundle(input, resolveId, load) {
  try {
    const bundle = await rollup.rollup({
      input, plugins: [{
        name: 'loader',
        resolveId(source, importer) { return resolveId(source, importer || ".") },
        load
      }]
    })

    const output = await bundle.generate({ format: "iife" })

    return new Ok(output.output[0].code)
  } catch (error) {
    return new Error(`${error}`)
  }
}

