# WasmEdge Reqwest Demo

In this project, we demonstrate how to use **reqwest** and **tokio** to build async http client in WebAssembly and execute it using [WasmEdge](https://github.com/WasmEdge/WasmEdge#readme).

## Why tokio in WasmEdge?

There are growing demands to perform network requests in WASM and cloud computing. But it would be inefficient to perform network requests synchronously so we need async in WASM. 

As tokio is widely accepted, we can bring many projects that depend on tokio to WASM if we can port tokio into WASM. After that, the developers can have async functions in WASM as well as efficient programs.

With the help of tokio support of WasmEdge, the developers can compile the projects that use tokio into WASM and execute it using WasmEdge.


## Prequsites

We need install rust and wasm target first.

```bash 
# install rust 
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install wasm target 
rustup target add wasm32-wasi
```

Then install the WasmEdge.

```bash
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
```

## Add dependencies in **Cargo.toml**

In this project, we add tokio and reqwest as dependencies.

```toml
[dependencies]
reqwest_wasi = "0.11"
tokio_wasi = { version = "1.21", features=["rt", "macros", "net", "time"]}
```

## Write the code 

We need to add some code into `src/main.rs`.

## Build and run it

First we need to compile the code.

```bash 
cargo build --target wasm32-wasi --release
```

Then we can run it using WasmEdge.

```bash
wasmedge target/wasm32-wasi/release/wasmedge_reqwest_demo.wasm
```

For simpilicity, we can add the following configs to `.cargo/config.toml`.

```toml
[build]
target="wasm32-wasi"

[target.wasm32-wasi]
runner = "wasmedge"
```

And then we can use `cargo run` to execute it directly.

# FAQ

## use of unstable library feature 'wasi_ext'

If you are using rustc 1.64, you may encounter this error. There are two options:

1. Update rustc to newer version. Validated versions are `1.65` and `1.59`.
2. Add `#![feature(wasi_ext)]` to the top of `mio/src/lib.rs`.
