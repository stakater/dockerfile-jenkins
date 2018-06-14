#!/usr/bin/env groovy
@Library('github.com/stakater/fabric8-pipeline-library@release-master-only')

def versionPrefix = ""
try {
    versionPrefix = VERSION_PREFIX
} catch (Throwable e) {
    versionPrefix = "1.0"
}

pushDockerImageFromMakefile {
    versionPrefix = versionPrefix
    dockerRegistryURL = "docker.io"
}