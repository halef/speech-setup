#!/usr/bin/env bash
set -e # Abort on error

# Locate this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paramaters
# TODO(langep): Make parameters configurable
install_location=/opt/jvxml
repo_url=https://github.com/halef/JVoiceXML.git
branch=master

# Cleanup trap in case of error
cleanup() {
    if [ $? -ne 0 ]; then
        # TODO(langep): Conditional cleanup based on where error happend
        rm -rf "$install_location"
    fi
}

trap cleanup EXIT

# Import helper functions.
source ${SCRIPT_DIR}/helper.sh

# Check dependencies
require_root
require_var ${JAVA_HOME:-""} "JAVA_HOME"
require_var ${M2_HOME:-""} "M2_HOME"
check_null_or_unset ${GRADLE_HOME:-""} "GRADLE_HOME"
require_command git



# Make install directories
# Note: Currently, JVoiceXML does not support install outside of source

# Clone repo
if ! check_dir "$install_location"; then
    git clone $repo_url "$install_location"
fi
cd "$install_location"
git checkout $branch
git pull

cp -r ${SCRIPT_DIR}/jvxml/run_JVXML.sh ${install_location}/main/run_JVXML.sh
chmod +x ${install_location}/main/run_JVXML.sh
sed -i -e "s|%%DB_WRITER_TMP_DIR_URL%%|/tmp|g" ${install_location}/main/run_JVXML.sh
sed -i -e "s|%%GANESHA_URL%%|http://localhost|g" ${install_location}/main/run_JVXML.sh
    
echo "export JVXML_SRC=${install_location}" >> /etc/bash.bashrc
echo "export JVXML_HOME=${install_location}" >> /etc/bash.bashrc

info "cd ${install_location}/main"
info "bash run_JVXML.sh"
info "tail -f jvxml.log"