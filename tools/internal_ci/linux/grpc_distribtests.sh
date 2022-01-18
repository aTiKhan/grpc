#!/bin/bash
# Copyright 2017 gRPC authors.
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

set -ex

# avoid slow finalization after the script has exited.
source $(dirname $0)/../../../tools/internal_ci/helper_scripts/move_src_tree_and_respawn_itself_rc

# change to grpc repo root
cd $(dirname $0)/../../..

source tools/internal_ci/helper_scripts/prepare_build_linux_rc

# some distribtests use a pre-registered binfmt_misc hook
# to automatically execute foreign binaries (such as aarch64)
# under qemu emulator.
source tools/internal_ci/helper_scripts/prepare_qemu_rc

set +ex
[[ -s /etc/profile.d/rvm.sh ]] && . /etc/profile.d/rvm.sh
set -e  # rvm commands are very verbose
rvm install ruby-2.5.7
rvm --default use ruby-2.5.7
set -ex

# Move packages generated by the previous step in the build chain to a place
# where they can be accessed from within a docker container that run the
# distribtests
mv ${KOKORO_GFILE_DIR}/github/grpc/artifacts input_artifacts || true
ls -R input_artifacts || true

tools/run_tests/task_runner.py -f distribtest linux -j 6 --inner_jobs 6
