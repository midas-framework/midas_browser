import gleam/fetch
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/string
import gleam/uri
import midas/browser/zip
import midas/defunctionalise as d
import midas/effect
import plinth/browser/crypto
import plinth/browser/crypto/subtle
import plinth/browser/location
import plinth/browser/window
import plinth/browser/window_proxy
import plinth/javascript/global
import snag

/// Run a task in the browser.
pub fn run_task(task) {
  run(task, fn(name) { snag.error("Unsupported effect: " <> name) })
}

/// Run effectful code in the browser.
pub fn run(
  task: d.Effect(a, key),
  unsupported: fn(String) -> a,
) -> promise.Promise(a) {
  case task {
    d.Done(value) -> promise.resolve(value)
    d.Fetch(request, resume) -> {
      use return <- promise.await(do_fetch(request))
      run(resume(return), unsupported)
    }
    d.Follow(url, resume) -> {
      use return <- promise.await(do_follow(url))
      run(resume(uri.parse(return)), unsupported)
    }
    d.Log(message, resume) -> {
      io.println(message)
      run(resume(Nil), unsupported)
    }
    d.Zip(files, resume) -> {
      use zipped <- promise.await(zip.zip(files))
      run(resume(Ok(zipped)), unsupported)
    }
    d.Bundle(..) -> promise.resolve(unsupported("Bundle"))
    d.ExportJsonWebKey(..) -> promise.resolve(unsupported("ExportJsonWebKey"))
    d.GenerateKeyPair(..) -> promise.resolve(unsupported("GenerateKeyPair"))
    d.Hash(algorithm:, bytes:, resume:) -> {
      use result <- promise.await(do_hash(algorithm, bytes))
      case result {
        Ok(hash) -> run(resume(hash), unsupported)
        Error(_reason) -> promise.resolve(unsupported("hash"))
      }
    }
    d.ReadDirectory(..) -> promise.resolve(unsupported("List"))
    d.ReadFile(..) -> promise.resolve(unsupported("Read"))
    d.Serve(..) -> promise.resolve(unsupported("Serve"))
    d.Sign(..) -> promise.resolve(unsupported("Sign"))
    d.StrongRandom(length:, resume:) -> {
      let result = do_random(length)
      case result {
        Ok(number) -> run(resume(number), unsupported)
        Error(_reason) -> promise.resolve(unsupported("strong_random"))
      }
    }
    d.UnixNow(..) -> promise.resolve(unsupported("UnixNow"))
    d.Visit(..) -> promise.resolve(unsupported("Visit"))
    d.WriteFile(..) -> promise.resolve(unsupported("Write"))
  }
}

/// Fetch a request
pub fn do_fetch(request) {
  use response <- promise.await(fetch.send_bits(request))
  case response {
    Ok(response) -> {
      use response <- promise.await(fetch.read_bytes_body(response))
      let response = case response {
        Ok(response) -> Ok(response)
        Error(fetch.NetworkError(s)) -> Error(effect.NetworkError(s))
        Error(fetch.UnableToReadBody) -> Error(effect.UnableToReadBody)
        Error(fetch.InvalidJsonBody) -> Error(effect.UnableToReadBody)
      }
      promise.resolve(response)
    }
    Error(fetch.NetworkError(s)) ->
      promise.resolve(Error(effect.NetworkError(s)))
    Error(fetch.UnableToReadBody) ->
      promise.resolve(Error(effect.UnableToReadBody))
    Error(fetch.InvalidJsonBody) ->
      promise.resolve(Error(effect.UnableToReadBody))
  }
}

pub fn do_follow(url) {
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
  case location.href(window_proxy.location(popup)) {
    "http" <> _ as location -> {
      window_proxy.close(popup)
      promise.resolve(location)
    }
    _ -> receive_redirect(popup, wait)
  }
}

pub fn do_hash(algorithm, bytes) {
  let algorithm = case algorithm {
    effect.Sha1 -> subtle.SHA1
    effect.Sha256 -> subtle.SHA256
    effect.Sha384 -> subtle.SHA384
    effect.Sha512 -> subtle.SHA512
  }
  subtle.digest(algorithm, bytes)
}

pub fn do_random(length) {
  case window.crypto(window.self()) {
    Ok(crypto) -> crypto.get_random_values(crypto, length)
    Error(Nil) -> Error("window.crypo is not present")
  }
}

pub fn do_wait(delay) {
  promise.new(fn(resolve) {
    global.set_timeout(delay, fn() { resolve(Nil) })
    Nil
  })
}
