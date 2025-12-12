# midas_browser

Run Midas effects and tasks in the browser.

[![Package Version](https://img.shields.io/hexpm/v/midas_browser)](https://hex.pm/packages/midas_browser)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/midas_browser/)

```sh
npm install --save @zip.js/zip.js
gleam add midas@1 midas_browser@1
```

```gleam
import midas/task as t
import midas/browser

/// Portable task definition that makes a web request and request some random bytes.
pub fn task(){
  let request = todo as "create a request"
  use response <- t.do(t.fetch(request))
  
  use random <- t.do(t.strong_random(10))
  t.done("task finished")
}
  
/// Run the task.
pub fn main() {
  browser.run(task())
}
```

Further documentation can be found at <https://hexdocs.pm/midas_browser>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
