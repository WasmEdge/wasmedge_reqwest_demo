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

In this project, we add `tokio` and `reqwest` as dependencies. You will need to add `wasi` specific patches to make those crates compile to Wasm.

```toml
[patch.crates-io]
tokio = { git = "https://github.com/second-state/wasi_tokio.git", branch = "v1.36.x" }
socket2 = { git = "https://github.com/second-state/socket2.git", branch = "v0.5.x" }
hyper = { git = "https://github.com/second-state/wasi_hyper.git", branch = "v0.14.x" }
reqwest = { git = "https://github.com/second-state/wasi_reqwest.git", branch = "0.11.x" }

[dependencies]
reqwest = { version = "0.11", default-features = false, features = ["rustls-tls"] }
tokio = { version = "1", features = ["rt", "macros", "net", "time"] }
```

## Write the code 

We need to add some code into `src/main.rs`.

## Build and run it

<details>

<summary> Note on Mac </summary>

> `ring v0.17` can't build on Mac with default clang.
> So, you need install wasi-sdk.

### [Download wasi-sdk](https://github.com/WebAssembly/wasi-sdk?tab=readme-ov-file#install)
```
export WASI_VERSION=22
export WASI_VERSION_FULL=${WASI_VERSION}.0
wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION_FULL}-macos.tar.gz
tar xvf wasi-sdk-${WASI_VERSION_FULL}-macos.tar.gz
```

### [Use the clang included in wasi-sdk for compilation.](https://github.com/WebAssembly/wasi-sdk?tab=readme-ov-file#use)
```
export WASI_SDK_PATH=`pwd`/wasi-sdk-${WASI_VERSION_FULL}
export CC="${WASI_SDK_PATH}/bin/clang --sysroot=${WASI_SDK_PATH}/share/wasi-sysroot"
```

</details>

First we need to compile the code. You will need to pass some flags to make sure that the Rust compiler knows to use the correct patches for the `wasmedge` target.

```bash 
RUSTFLAGS="--cfg wasmedge --cfg tokio_unstable" cargo build --target wasm32-wasi --release
```

Then we can run it using WasmEdge.

```bash
wasmedge target/wasm32-wasi/release/wasmedge_reqwest_demo.wasm
```

For simpilicity, we can add the following configs to `.cargo/config.toml`.

```toml
[build]
target="wasm32-wasi"
rustflags = ["--cfg", "wasmedge", "--cfg", "tokio_unstable"]

[target.wasm32-wasi]
runner = "wasmedge"
```

And then we can use `cargo build` and `cargo run`.

# FAQ

## use of unstable library feature 'wasi_ext'

If you are using rustc 1.64, you may encounter this error. There are two options:

1. Update rustc to newer version. Validated versions are `1.65` and `1.59`.
2. Add `#![feature(wasi_ext)]` to the top of `mio/src/lib.rs`.
