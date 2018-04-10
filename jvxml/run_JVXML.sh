#!/usr/bin/env bash
export HALEF_DB_WRITER_TMP_DIRECTORY=%%DB_WRITER_TMP_DIR_URL%%
export HALEF_DB_WRITER_GANESHA_URL=%%GANESHA_URL%%
export IP=`hostname -i`
mydir=`cd $(dirname $0); pwd`
cd $mydir
nohup gradle run >>jvxml.log 2>&1 &