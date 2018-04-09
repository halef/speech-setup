#!/usr/bin/env bash
set -e # Abort on error

# Locate this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paramaters
# TODO(langep): Make parameters configurable
download_location=~/src
install_location=/opt/cairo
repo_url=https://github.com/halef/cairo.git
branch=master

# Cleanup trap in case of error
cleanup() {
    if [ $? -ne 0 ]; then
        # TODO(langep): Conditional cleanup based on where error happend
        #rm -rf "$install_location"
        :
    fi
}

trap cleanup EXIT

# Load heler.sh functions
source ${SCRIPT_DIR}/helper.sh

# Check dependencies
require_root
require_var ${JAVA_HOME:-""} "JAVA_HOME"
require_var ${M2_HOME:-""} "M2_HOME"
require_command git

# Make download and install directories
mkdir -p "$download_location" "$install_location"
cd "$download_location"

# Clone repo
if ! check_dir cairo; then
    git clone $repo_url cairo
fi
cd cairo
git checkout $branch
git pull
git submodule init
git submodule update

# Install
bash scripts/install.sh $install_location

# Create group and user for cairo if they don't exist
if ! check_group cairo; then
    groupadd cairo
fi

if ! check_user cairo; then
    useradd -r -s /bin/false -g cairo cairo
fi

chown -R cairo $install_location
chmod +x $install_location/bin/start-cairo.sh
chmod +X $install_location/bin/cairo-start-helper.sh

cp ${SCRIPT_DIR}/init.d/cairo.init-debian /etc/init.d/cairo
chmod +x /etc/init.d/cairo
sed -i -e "s|%%CAIRO_HOME%%|${install_location}|g" /etc/init.d/cairo
sed -i -e "s|%%JAVA_HOME%%|${JAVA_HOME}|g" /etc/init.d/cairo
update-rc.d cairo defaults

echo "export CAIRO_HOME=${install_location}" >> /etc/bash.bashrc

info "Install complete."
info "You need to run the following before starting it."
info "source /etc/bash.bashrc"
info "${download_location}/cairo/scripts/configure.sh"
