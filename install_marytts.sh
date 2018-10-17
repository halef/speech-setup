#!/usr/bin/env bash
set -e # Abort on error

# Locate this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paramaters
# TODO(langep): Make parameters configurable
download_location=/usr/local/src
install_location=/opt/marytts
repo_url=https://github.com/marytts/marytts.git
branch=master
# Voices
poppy_archive=voice-dfki-poppy-5.2.zip
poppy_url=https://github.com/marytts/voice-dfki-poppy/releases/download/v5.2/${poppy_archive}
spike_archive=voice-dfki-spike-5.2.zip
spike_url=https://github.com/marytts/voice-dfki-spike/releases/download/v5.2/${spike_archive}

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
require_var ${JAVA_HOME:-""} "JAVA_HOME"
require_var ${GRADLE_HOME:-""} "GRADLE_HOME"
require_command wget
require_command git
require_command unzip

# Make download and install directories
mkdir -p "$download_location" "$install_location"
cd "$download_location"

# Clone repo
if ! check_dir marytts; then
    git clone $repo_url marytts
fi
pushd marytts
git checkout $branch
git pull

# Install
./gradlew installDist
cp -r build/install/marytts/* ${install_location}/.
popd

# Download and install voices
wget -O $poppy_archive $poppy_url
wget -O $spike_archive $spike_url
unzip -o $poppy_archive
unzip -o $spike_archive

mkdir -p ${install_location}/lib/voices
cp lib/*.jar  ${install_location}/lib/.
cp -r lib/voices/* ${install_location}/lib/voices/.

# Create group and user for marytts if they don't exist
if ! check_group marytts; then
    groupadd marytts
fi

if ! check_user marytts; then
    useradd -r -s /bin/false -g marytts marytts
fi
# TODO(langep): Maybe we should verify that marytts user is in marytts group

# Set permissions
chown -R marytts $install_location

# Setup service
cp ${SCRIPT_DIR}/init.d/marytts.init-debian /etc/init.d/marytts
chmod +x /etc/init.d/marytts
sed -i -e "s|%%MARYTTS_HOME%%|${install_location}|g" /etc/init.d/marytts
sed -i -e "s|%%JAVA_HOME%%|${JAVA_HOME}|g" /etc/init.d/marytts
update-rc.d marytts defaults

# Set environment
echo "export MARYTTS_HOME=${install_location}" >> /etc/bash.bashrc

info "Install complete. Run 'sudo service marytts start'"
