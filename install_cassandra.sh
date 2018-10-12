#!/usr/bin/env bash
set -e # Abort on error

# Locate this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paramaters
# TODO(langep): Make parameters configurable
download_location=/usr/local/src
install_location=/opt/cassandra
repo_url=https://git.code.sf.net/p/halef/cassandra
branch=master

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

# Clone repo
if ! check_dir cassandra; then
    git clone $repo_url cassandra
fi
cd cassandra
git checkout $branch
git pull

libws_dir=${download_location}/cassandra/communication/libwebsockets
kaldi_dir=${download_location}/cassandra/kaldi-trunk

info "Building libwebsockets"
mkdir -p ${libws_dir}/build
cd ${libws_dir}/build
cmake ..
make

info "Building kaldi"
cd ${kaldi_dir}/tools
make -j 2
cd ${kaldi_dir}/src
./configure
make depend -j 2
make -j 2

mkdir -p ${install_location}/bin
cp online2bin/STRM-ASR-server ${install_location}/bin/.

echo "export CASSANDRA_HOME=${cassandra_dir}" >> /etc/bash.bashrc

info "Script work done."
