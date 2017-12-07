#!/bin/sh
# Fix permissions on the given directory to allow group read/write of 
# regular files and execute of directories.

## source: https://github.com/openshift/jenkins/blob/master/2/contrib/jenkins/fix-permissions

## TODO: maybe its not needed! as it looks its needed for OpenShift

find $1 -exec chgrp 0 {} \;
find $1 -exec chmod g+rw {} \;
find $1 -type d -exec chmod g+x {} +