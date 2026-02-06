# WasmEdge Reqwest Demo

In this project, we demonstrate how to use **reqwest** and **tokio** to build async http client in WebAssembly and execute it using [WasmEdge](https://github.com/WasmEdge/WasmEdge#readme).

## Why tokio in WasmEdge?

There are growing demands to perform network requests in WASM and cloud computing. But it would be inefficient to perform network requests synchronously so we need async in WASM.

As tokio is widely accepted, we can bring many projects that depend on tokio to WASM if we can port tokio into WASM. After that, the developers can have async functions in WASM as well as efficient programs.

With the help of tokio support of WasmEdge, the developers can compile the projects that use tokio into WASM and execute it using WasmEdge.


## Prerequisites

We need install rust and wasm target first.

```bash
# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install wasm target
rustup target add wasm32-wasip1
```

Then install the WasmEdge.

```bash
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
```

## Add dependencies in **Cargo.toml**

In this project, we add `tokio` and `reqwest` as dependencies. You will need to add `wasi` specific patches to make those crates compile to Wasm.

```toml
[patch.crates-io]
tokio = { git = "https://github.com/second-state/wasi_tokio.git", branch = "v1.40.x" }
mio = { git = "https://github.com/second-state/wasi_mio.git", branch = "v1.0.x" }
socket2 = { git = "https://github.com/second-state/socket2.git", branch = "v0.5.x" }
hyper = { git = "https://github.com/second-state/wasi_hyper.git", branch = "v0.14.x" }
reqwest = { git = "https://github.com/second-state/wasi_reqwest.git", branch = "0.11.x" }

[dependencies]
reqwest = { version = "0.11", default-features = false, features = ["rustls-tls"] }
tokio = { version = "1", features = ["rt", "macros", "net", "time"] }
tokio-util = { version = ">=0.7.1, <0.7.18" }
```

## Write the code

We need to add some code into `src/main.rs`.

## Build and run it

<details>

<summary> Note on Mac and other platforms </summary>

> `ring v0.17` can't build with the default system clang because it does not
> support the `wasm32-wasip1` target. You need to install wasi-sdk and point
> the build at its clang.

### [Download wasi-sdk](https://github.com/WebAssembly/wasi-sdk?tab=readme-ov-file#install)

Pick the tarball for your platform:

```bash
export WASI_VERSION=25
export WASI_VERSION_FULL=${WASI_VERSION}.0

# macOS Apple Silicon (arm64)
wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION_FULL}-arm64-macos.tar.gz
tar xvf wasi-sdk-${WASI_VERSION_FULL}-arm64-macos.tar.gz

# macOS Intel (x86_64)
# wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION_FULL}-x86_64-macos.tar.gz
# tar xvf wasi-sdk-${WASI_VERSION_FULL}-x86_64-macos.tar.gz

# Linux (x86_64)
# wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_VERSION}/wasi-sdk-${WASI_VERSION_FULL}-x86_64-linux.tar.gz
# tar xvf wasi-sdk-${WASI_VERSION_FULL}-x86_64-linux.tar.gz
```

### [Set `CC_wasm32_wasip1` to the wasi-sdk clang](https://github.com/WebAssembly/wasi-sdk?tab=readme-ov-file#use)

```bash
export WASI_SDK_PATH=`pwd`/wasi-sdk-${WASI_VERSION_FULL}-arm64-macos
export CC_wasm32_wasip1="${WASI_SDK_PATH}/bin/clang"
```

Adjust the directory name to match the tarball you downloaded.

</details>

First we need to compile the code. You will need to pass some flags to make sure that the Rust compiler knows to use the correct patches for the `wasmedge` target.

```bash
RUSTFLAGS="--cfg wasmedge --cfg tokio_unstable" cargo build --target wasm32-wasip1 --release
```

Then we can run it using WasmEdge.

```bash
wasmedge target/wasm32-wasip1/release/wasmedge_reqwest_demo.wasm
```

For simplicity, we can add the following configs to `.cargo/config.toml`.

```toml
[build]
target = "wasm32-wasip1"
rustflags = ["--cfg", "wasmedge", "--cfg", "tokio_unstable"]

[target.wasm32-wasip1]
runner = "wasmedge"
```

And then we can use `cargo build` and `cargo run`.

# FAQ

## use of unstable library feature 'wasi_ext'

If you are using rustc 1.64, you may encounter this error. There are two options:

1. Update rustc to newer version. Validated versions are `1.65` and `1.59`.
2. Add `#![feature(wasi_ext)]` to the top of `mio/src/lib.rs`.
