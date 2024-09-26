import gleam/javascript/promise.{type Promise}

@external(javascript, "../../midas_browser_rollup_ffi.mjs", "bundle")
pub fn do_bundle(
  input: String,
  resolve_id: fn(String, String) -> String,
  load: fn(String) -> String,
) -> Promise(Result(String, String))

pub fn bundle(mod, func, resolve_id, load) {
  let export_filename = "rollup_export.js"
  let export_content =
    "import { " <> func <> " } from \"./" <> mod <> ".mjs\";\n" <> func <> "()"
  do_bundle(
    export_filename,
    fn(source, importer) {
      case source {
        s if s == export_filename -> export_filename
        _ -> resolve_id(source, importer)
      }
    },
    fn(module) {
      case module {
        s if s == export_filename -> export_content
        _ -> load(module)
      }
    },
  )
}
