import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/string

pub type Project

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "new_project")
pub fn new_project() -> Promise(Result(Project, String))

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "write_module")
pub fn write_module(project: Project, name: String, code: String) -> Nil

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "write_file")
pub fn write_file(project: Project, path: String, text: String) -> Nil

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "write_file_bytes")
pub fn write_file_bytes(project: Project, path: String, bits: BitArray) -> Nil

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "read_file_bytes")
pub fn read_file_bytes(
  project: Project,
  path: String,
) -> Result(BitArray, String)

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "compile_package")
pub fn compile_package(project: Project, target: String) -> Result(Nil, String)

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "read_compiled_javascript")
pub fn read_compiled_javascript(
  project: Project,
  module: String,
) -> Result(String, String)

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "reset_warnings")
pub fn reset_warnings(project: Project) -> Nil

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "pop_warning")
pub fn pop_warning(project: Project) -> Result(String, Nil)

fn do_take_warnings(project, acc) {
  case pop_warning(project) {
    Ok(warning) -> do_take_warnings(project, [warning, ..acc])
    Error(Nil) -> list.reverse(acc)
  }
}

pub fn take_warnings(project) {
  do_take_warnings(project, [])
  |> list.map(string.trim_start(_))
}

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "run")
pub fn run(
  project: Project,
  module: String,
  function: String,
) -> Promise(Result(Dynamic, String))

@external(javascript, "../../midas_browser_gleam_ffi.mjs", "runWithClient")
pub fn run_with_client(
  client_id: String,
  project: String,
  module: String,
  function: String,
  arg: Dynamic,
) -> Promise(Result(Dynamic, String))
// @external(javascript, "../../midas_browser_gleam_ffi.mjs", "compile")
// fn do_compile(dir: Array(#(String, String))) -> Promise(Result(String, String))

// pub fn compile(dir: List(#(String, String))) {
//   do_compile(array.from_list(dir))
// }
