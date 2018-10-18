#!/usr/bin/env bash
set -e # Abort on error

# Locate this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paramaters
# TODO(langep): Make parameters configurable
download_location=/usr/local/src
install_location=/opt/cassandra
repo_url=https://github.com/halef/halef-asr.git
branch=master
lws_repo_url=https://github.com/halef/libwebsockets.git
lws_branch=v1.5-stable
kaldi_repo_url=https://github.com/halef/kaldi.git
kaldi_branch=5.2

# Cleanup trap in case of error
cleanup() {
    if [ $? -ne 0 ]; then
        # TODO(langep): Conditional cleanup based on where error happend
        rm -rf "$install_location"
    fi
}

trap cleanup EXIT

# Load heler.sh functions
source ${SCRIPT_DIR}/helper.sh

# Check dependencies
require_root
require_command git

# Make download and install directories
mkdir -p "$download_location" "$install_location"
cd "$download_location"

# Libwebsockets setup
cd ${download_location}
if ! check_dir libwebsockets; then
    git clone $lws_repo_url libwebsockets
fi
cd libwebsockets
git checkout $lws_branch
git pull
libws_dir=${download_location}/libwebsockets

mkdir -p ${libws_dir}/build
cd ${libws_dir}/build
cmake -DLWS_WITH_SSL=0 ..
make

# Kaldi setup
cd ${download_location}
if ! check_dir kaldi; then
    git clone $kaldi_repo_url kaldi
fi
cd kaldi
git checkout $kaldi_branch
git pull
kaldi_dir=${download_location}/kaldi

cd ${kaldi_dir}/tools
make -j 4
cd ${kaldi_dir}/src
./configure
make depend -j 4
make -j 4

# Clone cassandra repo and build it
if ! check_dir cassandra; then
    git clone $repo_url cassandra
fi
cd cassandra
git checkout $branch
git pull

LIBWEB_BUILD=${libws_dir}/build KALDI_SRC=${kaldi_dir}/src make

mkdir -p ${install_location}/bin
cp STRM-ASR-server ${install_location}/bin/.

echo "export CASSANDRA_HOME=${cassandra_dir}" >> /etc/bash.bashrc
info "Script work done."
