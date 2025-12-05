import gleam/fetch
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/string
import gleam/uri
import midas/browser/zip
import midas/effect as e
import plinth/browser/window

// can't be part of main midas reliance on node stuff. would need to be sub package
pub fn run(task) {
  case task {
    e.Done(value) -> promise.resolve(value)
    e.Fetch(request, resume) -> {
      use return <- promise.await(do_fetch(request))
      run(resume(return))
    }
    e.Follow(url, resume) -> {
      use return <- promise.await(do_follow(url))
      run(resume(uri.parse(return)))
    }
    e.Log(message, resume) -> {
      io.println(message)
      run(resume(Ok(Nil)))
    }
    e.Zip(files, resume) -> {
      use zipped <- promise.await(zip.zip(files))
      run(resume(Ok(zipped)))
    }
    e.Bundle(..) -> panic as { "Unsupported effect: " <> "Bundle" }
    e.ExportJsonWebKey(..) ->
      panic as { "Unsupported effect: " <> "ExportJsonWebKey" }
    e.GenerateKeyPair(..) ->
      panic as { "Unsupported effect: " <> "GenerateKeyPair" }
    e.Hash(..) -> panic as { "Unsupported effect: " <> "Hash" }
    e.List(..) -> panic as { "Unsupported effect: " <> "List" }
    e.Read(..) -> panic as { "Unsupported effect: " <> "Read" }
    e.Serve(..) -> panic as { "Unsupported effect: " <> "Serve" }
    e.Sign(..) -> panic as { "Unsupported effect: " <> "Sign" }
    e.StrongRandom(..) -> panic as { "Unsupported effect: " <> "StrongRandom" }
    e.UnixNow(..) -> panic as { "Unsupported effect: " <> "UnixNow" }
    e.Visit(..) -> panic as { "Unsupported effect: " <> "Visit" }
    e.Write(..) -> panic as { "Unsupported effect: " <> "Write" }
  }
}

pub fn do_fetch(request) {
  use response <- promise.await(fetch.send_bits(request))
  case response {
    Ok(response) -> {
      use response <- promise.await(fetch.read_bytes_body(response))
      let response = case response {
        Ok(response) -> Ok(response)
        Error(fetch.NetworkError(s)) -> Error(e.NetworkError(s))
        Error(fetch.UnableToReadBody) -> Error(e.UnableToReadBody)
        Error(fetch.InvalidJsonBody) -> panic
      }
      promise.resolve(response)
    }
    Error(fetch.NetworkError(s)) -> promise.resolve(Error(e.NetworkError(s)))
    Error(fetch.UnableToReadBody) -> promise.resolve(Error(e.UnableToReadBody))
    Error(fetch.InvalidJsonBody) -> panic
  }
}

fn do_follow(url) {
  let url = uri.to_string(url)
  let frame = #(600, 700)
  let assert Ok(popup) = open(url, frame)
  receive_redirect(popup, 100)
}

pub fn open(url, frame_size) {
  let space = #(
    window.outer_width(window.self()),
    window.outer_height(window.self()),
  )
  let #(#(offset_x, offset_y), #(inner_x, inner_y)) = center(frame_size, space)
  let features =
    string.concat([
      "popup",
      ",width=",
      int.to_string(inner_x),
      ",height=",
      int.to_string(inner_y),
      ",left=",
      int.to_string(offset_x),
      ",top=",
      int.to_string(offset_y),
    ])

  window.open(url, "_blank", features)
}

pub fn center(inner, outer) {
  let #(inner_x, inner_y) = inner
  let #(outer_x, outer_y) = outer

  let inner_x = int.min(inner_x, outer_x)
  let inner_y = int.min(inner_y, outer_y)

  let offset_x = { outer_x - inner_x } / 2
  let offset_y = { outer_y - inner_y } / 2

  #(#(offset_x, offset_y), #(inner_x, inner_y))
}

pub fn receive_redirect(popup, wait) {
  use Nil <- promise.await(do_wait(wait))
  case window.location_of(popup) {
    Ok("http" <> _ as location) -> {
      window.close(popup)
      promise.resolve(location)
    }
    _ -> receive_redirect(popup, wait)
  }
}

import plinth/javascript/global

pub fn do_wait(delay) {
  promise.new(fn(resolve) {
    global.set_timeout(delay, fn() { resolve(Nil) })
    Nil
  })
}
