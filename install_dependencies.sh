#!/usr/bin/env bash
set -e # Abort on error

# Locate this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paramaters
# TODO(langep): Make parameters configurable
download_location=~/src
install_location=/opt/tools
gradle_version=3.4.1
maven_version=3.3.9

jdk_archive=jdk-8u181-linux-x64.tar.gz
jdk_url=http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/${jdk_archive}

gradle_archive=gradle-${gradle_version}-bin.zip
maven_archive=apache-maven-${maven_version}-bin.tar.gz
gradle_url=https://downloads.gradle.org/distributions/${gradle_archive}
maven_url=http://www-eu.apache.org/dist/maven/maven-3/${maven_version}/binaries/${maven_archive}

maven_name=${maven_archive%-bin.tar.gz}
gradle_name=${gradle_archive%-bin.zip}
jdk_name=jdk1.8.0_161

# Cleanup trap in case of error
cleanup() {
    if [ $? -ne 0 ]; then
        # TODO(langep): Conditional cleanup based on where error happend
        rm -rf "$install_location"
    fi
}

trap cleanup EXIT

# Update packages and install dependencies
apt-get update
apt-get install -y --no-install-recommends build-essential unzip git wget \
    lib32z1 sharutils cmake zlib1g-dev libssl-dev g++ automake autoconf \
    libtool subversion python-minimal libatlas3-base

# Make download and install directories
mkdir -p "$download_location" "$install_location"
cd "${download_location}"

# Download and unpack the source archive
if [ ! -f ${gradle_archive} ]; then
    wget -O $gradle_archive $gradle_url
fi

if [ ! -f ${maven_archive} ]; then
    wget -O $maven_archive $maven_url
fi

if [ ! -f ${jdk_archive} ]; then
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie" \
        --no-check-certificate -c -O $jdk_archive $jdk_url
fi

# Unpacking and installing

tar -xvf $maven_archive
tar -xvf $jdk_archive
unzip $gradle_archive

cp -r $maven_name "${install_location}/${maven_name}"
ln -s "${install_location}/${maven_name}" "${install_location}/maven"

cp -r $gradle_name "${install_location}/${gradle_name}"
ln -s ${install_location}/${gradle_name} "${install_location}/gradle"

cp -r $jdk_name "${install_location}/${jdk_name}"
ln -s ${install_location}/${jdk_name} "${install_location}/java"

info "Press [Q] to install JSAPI"
sh ${SCRIPT_DIR}/jsapi.sh
mkdir -p ${install_location}/java/lib/ext
mv jsapi.jar ${install_location}/java/lib/ext/jsapi-1.0.jar

# Finishing setup of environment
echo "export JAVA_HOME=${install_location}/java" >> /etc/bash.bashrc
echo "export GRADLE_HOME=${install_location}/gradle" >> /etc/bash.bashrc
echo "export M2_HOME=${install_location}/maven" >> /etc/bash.bashrc
echo 'export PATH=${M2_HOME}/bin:${GRADLE_HOME}/bin:${JAVA_HOME}/bin:${PATH}' >> /etc/bash.bashrc
