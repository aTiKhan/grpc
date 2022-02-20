#!/bin/bash
# Copyright 2021 The gRPC Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create placeholders ("fake artifacts") for native binaries that
# can't be built locally on current platform.

set -ex

cd "$(dirname "$0")/../../.."

cd src/csharp

# Create fake grpc_csharp_ext artifacts
mkdir -p nativelibs
pushd nativelibs

if [[ "$(uname)" != "Linux" ]]
then
   mkdir -p csharp_ext_linux_x64
   touch csharp_ext_linux_x64/libgrpc_csharp_ext.so
   touch csharp_ext_linux_x64/libgrpc_csharp_ext.dbginfo.so

   mkdir -p csharp_ext_linux_x86
   touch csharp_ext_linux_x86/libgrpc_csharp_ext.so

   mkdir -p csharp_ext_linux_aarch64
   touch csharp_ext_linux_aarch64/libgrpc_csharp_ext.so
   touch csharp_ext_linux_aarch64/libgrpc_csharp_ext.dbginfo.so

   mkdir -p csharp_ext_linux_android_armeabi-v7a
   touch csharp_ext_linux_android_armeabi-v7a/libgrpc_csharp_ext.so

   mkdir -p csharp_ext_linux_android_arm64-v8a
   touch csharp_ext_linux_android_arm64-v8a/libgrpc_csharp_ext.so

   mkdir -p csharp_ext_linux_android_x86
   touch csharp_ext_linux_android_x86/libgrpc_csharp_ext.so
fi

if [[ "$(uname)" != "Darwin" ]]
then
    mkdir -p csharp_ext_macos_x64
    touch csharp_ext_macos_x64/libgrpc_csharp_ext.dylib

    mkdir -p csharp_ext_macos_ios
    touch csharp_ext_macos_ios/libgrpc_csharp_ext.a
    touch csharp_ext_macos_ios/libgrpc.a
fi

if [[ "$(uname)" != "WindowsNT" ]]
then
    mkdir -p csharp_ext_windows_x64
    touch csharp_ext_windows_x64/grpc_csharp_ext.dll
    touch csharp_ext_windows_x64/grpc_csharp_ext.pdb

    mkdir -p csharp_ext_windows_x86
    touch csharp_ext_windows_x86/grpc_csharp_ext.dll
    touch csharp_ext_windows_x86/grpc_csharp_ext.pdb
fi

popd

# Create fake protoc artifacts
mkdir -p protoc_plugins
pushd protoc_plugins

if [[ "$(uname)" != "Linux" ]]
then
  mkdir -p protoc_linux_x64
  touch protoc_linux_x64/protoc
  touch protoc_linux_x64/grpc_csharp_plugin

  mkdir -p protoc_linux_x86
  touch protoc_linux_x86/protoc
  touch protoc_linux_x86/grpc_csharp_plugin

  mkdir -p protoc_linux_aarch64
  touch protoc_linux_aarch64/protoc
  touch protoc_linux_aarch64/grpc_csharp_plugin
fi

if [[ "$(uname)" != "Darwin" ]]
then
    mkdir -p protoc_macos_x64
    touch protoc_macos_x64/protoc
    touch protoc_macos_x64/grpc_csharp_plugin
fi

if [[ "$(uname)" != "WindowsNT" ]]
then
    mkdir -p protoc_windows_x86
    touch protoc_windows_x86/protoc.exe
    touch protoc_windows_x86/grpc_csharp_plugin.exe

    mkdir -p protoc_windows_x64
    touch protoc_windows_x64/protoc.exe
    touch protoc_windows_x64/grpc_csharp_plugin.exe
fi

popd
