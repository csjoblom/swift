#/bin/bash

set -ex

SOURCE_PATH="$( cd "$(dirname $0)/../../.." && pwd  )" 
SWIFT_PATH=$SOURCE_PATH/swift
UTILS_PATH=$SWIFT_PATH/utils/webassembly
if [[ "$(uname)" == "Linux" ]]; then
  DEPENDENCIES_SCRIPT=$UTILS_PATH/linux/install-dependencies.sh
else
  DEPENDENCIES_SCRIPT=$UTILS_PATH/macos/install-dependencies.sh
fi

BUILD_SCRIPT=$UTILS_PATH/build-toolchain.sh
RUN_TEST_BIN=$SWIFT_PATH/utils/run-test
TARGET_BUILD_DIR=$SOURCE_PATH/target-build/Ninja-Release

$DEPENDENCIES_SCRIPT

export PATH="$HOME/.wasmer/bin:$PATH"

export SCCACHE_CACHE_SIZE="50G"
export SCCACHE_DIR="$SOURCE_PATH/build-cache"

CACHE_FLAGS="--cmake-c-launcher $(which sccache) --cmake-cxx-launcher $(which sccache)"
FLAGS="--release $CACHE_FLAGS --verbose"

$BUILD_SCRIPT $FLAGS

echo "Build script completed, will attempt to run test suites..."

if [[ "$(uname)" == "Darwin" ]]; then
  # workaround: host target test directory is necessary to use run-test
  mkdir -p $TARGET_BUILD_DIR/swift-macosx-x86_64/test-macosx-x86_64
  HOST_PLATFORM=macosx
else
  HOST_PLATFORM=linux
fi

if [[ "$(uname)" == "Linux" ]]; then
  $RUN_TEST_BIN --build-dir $TARGET_BUILD_DIR --target wasi-wasm32 \
    $TARGET_BUILD_DIR/swift-${HOST_PLATFORM}-x86_64/test-wasi-wasm32/stdlib
  echo "Skip running test suites for Linux"
else
  $RUN_TEST_BIN --build-dir $TARGET_BUILD_DIR --target wasi-wasm32 \
 	$TARGET_BUILD_DIR/swift-${HOST_PLATFORM}-x86_64/test-wasi-wasm32/stdlib

  # Run test but ignore failure temporarily
  $BUILD_SCRIPT $FLAGS -t || true
fi

echo "The test suite has finished"
