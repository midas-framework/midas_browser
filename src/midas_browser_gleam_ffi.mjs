import { Ok, Error, BitArray, List } from "./gleam.mjs";

// This is a hack that allows wasm to run in node
// import { readFileSync } from "fs";

// //  node output from gleam project using dagger
// globalThis.fetch = function (arg) {
//     return readFileSync(arg)
//     // throw new Error("What the finangle")
// }

let compiler;

export async function init() {
    const wasm = await import("/wasm-compiler/gleam_wasm.js")
    await wasm.default();
    wasm.initialise_panic_hook();
    const nextID = 0
    compiler = {wasm, nextID}
  }
  
export async function new_project(){
  try { 
    if (!compiler) await init()

    const id = compiler.nextID
    compiler.nextID++
    return new Ok(id)
  } catch (error) {
    return new Error(error.toString())
  }
}

export function write_module(id, name, code) {
  return compiler.wasm.write_module(id, name, code)
}

export function write_file(id, path, text) {
  return compiler.wasm.write_file(id, path, text)
}

export function write_file_bytes(id, path, bitArray) {
  return compiler.wasm.write_file_bytes(id, path, bitArray.buffer)
}

export function read_file_bytes(id, path) {
  const bytes = compiler.wasm.read_file_bytes(id, path)
  if (bytes) {
    return new Ok(new BitArray(bytes))    
  } else {
    return new Error()
  }
}

export function compile_package(id, target) {
  try {
    return new Ok(compiler.wasm.compile_package(id, target))
  } catch (error) {
    return new Error(`${error}`)
  }
}

export function read_compiled_javascript(id, module) {
  return compiler.wasm.read_compiled_javascript(id, module)
}

export function reset_warnings(id,) {
  return compiler.wasm.reset_warnings(id,)
}

export function pop_warning(id) {
  const warning = compiler.wasm.pop_warning(id)
  if (warning) {
    return new Ok(warning)
  } else {
    return new Error()
  }
}

var runCount = 0
export async function run(id, module, fn) {
  runCount++
  try {
    const mod = await import(`/sandbox/gleam/${runCount}/${id}/${module}.mjs`) 
    return new Ok(await mod[fn]())
  } catch (error) {
    return new Error(`${error}`)
  }
}

// use same run count
export async function runWithClient(clientID, projectID, module, fn, arg) {
  runCount++
  try {
    const mod = await import(`/sandbox/gleam/${runCount}/${clientID}/${projectID}/${module}.mjs`) 
    return new Ok(await mod[fn](arg))
  } catch (error) {
    return new Error(`${error}`)
  }
}

