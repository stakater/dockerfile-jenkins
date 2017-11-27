# dockerfile-jenkins

dockerfile for jenkins

## Acknowledgement

This Dockerfile is based on following:

- [OpenShift Jenkins](https://github.com/openshift/jenkins)
- [JenkinsCI Dockerfile for Jenkins for Alpine](https://github.com/jenkinsci/docker/tree/alpine)

## ToDo's

- [ ] remove from base image
```
RUN     addgroup stakater && \
        adduser -S -G stakater stakater && \
        adduser -S -G stakater sudo

# Expose the working directory
VOLUME 	["/home/stakater"]
```
- [ ] run a plain jenkins without any plugins!
- [ ] update to latest version of Jenkins
- [ ] remove openshift pieces from run.sh
- [ ] use JRE instead of JDK
- [ ] ensure final running application (jenkins) becomes the container’s PID 1. 
- [ ] ensure it can't have root access
- [ ] remove stakater user, group and volume from the base folder

## Source

https://github.com/jenkinsci/docker
https://hub.docker.com/r/jenkins/jenkins/

## Plugins

### Required


## Others

* printenv
* `HOME=/var/jenkins_home`
* `cd /var/jenkins_home ls -l`

```
-rw-r--r--  1 jenkins jenkins 1684 Nov 17 21:17 config.xml
lrwxrwxrwx  1 jenkins jenkins   21 Nov 17 21:17 config.xml.tpl -> ..data/config.xml.tpl
-rw-r--r--  1 jenkins jenkins 1031 Nov 17 21:17 copy_reference_file.log
-rw-r--r--  1 jenkins jenkins  156 Nov 17 21:17 hudson.model.UpdateCenter.xml
lrwxrwxrwx  1 jenkins jenkins   29 Nov 17 21:17 hudson.tasks.Maven.xml -> ..data/hudson.tasks.Maven.xml
-rw-------  1 jenkins jenkins 1712 Nov 17 21:17 identity.key.enc
-rw-r--r--  1 jenkins jenkins   94 Nov 17 21:17 jenkins.CLI.xml
-rw-r--r--  1 jenkins jenkins    4 Nov 17 21:17 jenkins.install.InstallUtil.lastExecVersion
-rw-r--r--  1 jenkins jenkins    4 Nov 17 21:17 jenkins.install.UpgradeWizard.state
lrwxrwxrwx  1 jenkins jenkins   58 Nov 17 21:17 jenkins.plugins.nodejs.tools.NodeJSInstallation.xml -> ..data/jenkins.plugins.nodejs.tools.NodeJSInstallation.xml
drwxr-xr-x  2 jenkins jenkins 4096 Nov 17 21:17 jobs
lrwxrwxrwx  1 jenkins jenkins   19 Nov 17 21:17 keycloak.url -> ..data/keycloak.url
drwxr-xr-x  3 jenkins jenkins 4096 Nov 17 21:17 logs
-rw-r--r--  1 jenkins jenkins  907 Nov 17 21:17 nodeMonitors.xml
drwxr-xr-x  2 jenkins jenkins 4096 Nov 17 21:17 nodes
lrwxrwxrwx  1 jenkins jenkins   47 Nov 17 21:17 org.jenkinsci.main.modules.sshd.SSHD.xml -> ..data/org.jenkinsci.main.modules.sshd.SSHD.xml
lrwxrwxrwx  1 jenkins jenkins   68 Nov 17 21:17 org.jenkinsci.plugins.updatebot.GlobalPluginConfiguration.xml -> ..data/org.jenkinsci.plugins.updatebot.GlobalPluginConfiguration.xml
drwxr-xr-x  2 jenkins jenkins 4096 Nov 17 21:17 plugins
lrwxrwxrwx  1 jenkins jenkins   22 Nov 17 21:17 pre-shutdown.sh -> ..data/pre-shutdown.sh
lrwxrwxrwx  1 jenkins jenkins   25 Nov 17 21:17 scriptApproval.xml -> ..data/scriptApproval.xml
-rw-r--r--  1 jenkins jenkins   64 Nov 17 21:17 secret.key
-rw-r--r--  1 jenkins jenkins    0 Nov 17 21:17 secret.key.not-so-secret
drwx------  4 jenkins jenkins 4096 Nov 17 21:17 secrets
drwxr-xr-x  2 jenkins jenkins 4096 Nov 17 21:17 updates
drwxr-xr-x  2 jenkins jenkins 4096 Nov 17 21:17 userContent
drwxr-xr-x  3 jenkins jenkins 4096 Nov 17 21:17 users
drwxr-xr-x 10 jenkins jenkins 4096 Nov 17 21:17 war
```

* to check uid, gid and groups run a command `id`

```
bash-4.3$ id
uid=1000(jenkins) gid=1000(jenkins) groups=1000(jenkins)
```

## Building?

Build an image:
`docker build -t stakater/jenkins2 .`

docker run -it --rm stakater/jenkins2

## References

- old fabric8 jenkins image: `https://github.com/fabric8io/jenkins-docker`
- current fabric8 jenkins image: `https://github.com/openshift/jenkins` & `https://github.com/fabric8io/openshift-jenkins-s2i-config`
- base jenkins docker image: `https://github.com/jenkinsci/docker/blob/master/Dockerfile-alpine`
- all the magic is happening here: `https://github.com/openshift/jenkins/blob/master/2/contrib/s2i/run`

`find / -type d -name "*blueocean-git-pipeline*" -print`

- from `https://github.com/agileek/docker-jenkins/blob/master/Dockerfile`

```
FROM openjdk:8u141-jdk

RUN apt-get update && apt-get install -y wget git curl zip && rm -rf /var/lib/apt/lists/*

ENV JENKINS_VERSION 2.91
RUN mkdir /usr/share/jenkins/
RUN useradd -d /home/jenkins -m -s /bin/bash jenkins

COPY init.groovy /tmp/WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy
RUN curl -L http://mirrors.jenkins-ci.org/war/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
  && cd /tmp && zip -g /usr/share/jenkins/jenkins.war WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy && rm -rf /tmp/WEB-INF

ENV JENKINS_HOME /var/jenkins_home
RUN usermod -m -d "$JENKINS_HOME" jenkins && chown -R jenkins "$JENKINS_HOME"
VOLUME /var/jenkins_home

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

USER jenkins

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
```

jenkins.sh

```
#! /bin/bash

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
   exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
```

---

The typical workflow to support a matching volume from the default image is:

- On the host machine, create a jenkins group with a GID that matches Jenkins Docker image
- On the host machine, create a jenkins user with a UID that matches the Jenkins Docker image, and assign this user to the jenkins group, created
- On the host machine, run Jenkins Docker container with a volume binding of your host machine jenkins user's home to the container's $JENKINS_HOME.

It's reasonable to expect the creation of a jenkins user and group on the host system for typical usage, I'll suggest that it's better to set the jenkins UID and GID in the Jenkins Docker image to be within the system user UID range and system group GID range, respectively. Setting the UID and GID within the system ranges will avoid having the jenkins user display in GUI login screens (see here and here). Although Jenkins Docker should not be run on a server with a GUI environment in production, you can expect your users to try it out in desktop machines. (You can probably expect some users to run Jenkins Docker in "production" from desktop machines, too.)

The major Linux distributions' user- and group-creation tools increment starting from SYS_UID_MIN and SYS_GID_MIN (100 on major Linux distros). RedHat/CentOS have a lower SYS_UID_MAX and SYS_GID_MAX (499). Assuming it's unlikely a system will have greater than 100 system users and groups, a value between 200 and 500 should be fine.

Maybe check the FreeBSD registered UIDs and FreeBSD registered GIDs to get an idea of what other services might use to make a collision even more unlikely. (I realize this is for a Unix, not Linux, but all the more chance to avoid collision.)

For example uid=386 and gid=386 meet all of the criteria above.

With all this said, it is impossible to avoid a UID/GID collision in every possible scenario. The best Jenkins Docker project can do is pick a value with an unlikely collision, like 386, and provide clear documentation on how to deal with a collision. I described this process in #277 under the heading "More information on custom builds of Jenkins Docker (workaround 2):". (As a side note, kudos to the Jenkins Docker maintainers for exposing uid and gid as ARGs.)

https://github.com/jenkinsci/docker/issues/112#issuecomment-228553691
https://github.com/jenkinsci/docker/issues/277#issuecomment-226582397

---

## Jenkins sha / checksum

most of the values for the arguments are obvious except for the value for JENKINS_SHA. I have found these values located in the corresponding subdirectory of your desired Jenkins version under https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/. For example, the SHA1 checksum for Jenkins 2.2 is located at https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/2.2/jenkins-war-2.2.war.sha1

need to build the url manually and then download the file!


https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/2.60.3/jenkins-war-2.60.3.war.sha1

---

# OpenShift Jenkins Dockerfile

https://github.com/openshift/jenkins/blob/master/2/Dockerfile

```
FROM openshift/origin

# Jenkins image for OpenShift
#
# This image provides a Jenkins server, primarily intended for integration with
# OpenShift v3.
#
# Volumes:
# * /var/jenkins_home
# Environment:
# * $JENKINS_PASSWORD - Password for the Jenkins 'admin' user.

MAINTAINER Ben Parees <bparees@redhat.com>

# Jenkins LTS packages from
# https://pkg.jenkins.io/redhat-stable/
ENV JENKINS_VERSION=2 \
    HOME=/var/lib/jenkins \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_UC=https://updates.jenkins-ci.org \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

LABEL k8s.io.description="Jenkins is a continuous integration server" \
      k8s.io.display-name="Jenkins 2" \
      openshift.io.expose-services="8080:http" \
      openshift.io.tags="jenkins,jenkins2,ci" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

# 8080 for main web interface, 50000 for slave agents
EXPOSE 8080 50000

RUN curl https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins-ci.org.key && \
    yum install -y centos-release-scl-rh && \
    INSTALL_PKGS="dejavu-sans-fonts rsync gettext git tar zip unzip java-1.8.0-openjdk java-1.8.0-openjdk.i686 java-1.8.0-openjdk-devel java-1.8.0-openjdk-devel.i686 jenkins-2.73.3-1.1" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.UTF-8

COPY ./contrib/openshift /opt/openshift
COPY ./contrib/jenkins /usr/local/bin
ADD ./contrib/s2i /usr/libexec/s2i

RUN /usr/local/bin/install-plugins.sh /opt/openshift/base-plugins.txt && \
    # need to create <plugin>.pinned files when upgrading "core" plugins like credentials or subversion that are bundled with the jenkins server
    # Currently jenkins v2 does not embed any plugins, but for reference:
    # touch /opt/openshift/plugins/credentials.jpi.pinned && \
    rmdir /var/log/jenkins && \
    chmod 775 /etc/passwd && \
    chmod -R 775 /etc/alternatives && \
    chmod -R 775 /var/lib/alternatives && \
    chmod -R 775 /usr/lib/jvm && \
    chmod 775 /usr/bin && \
    chmod 775 /usr/lib/jvm-exports && \
    chmod 775 /usr/share/man/man1 && \
    chmod 775 /var/lib/origin && \
    unlink /usr/bin/java && \
    unlink /usr/bin/jjs && \
    unlink /usr/bin/keytool && \
    unlink /usr/bin/orbd && \
    unlink /usr/bin/pack200 && \
    unlink /usr/bin/policytool && \
    unlink /usr/bin/rmid && \
    unlink /usr/bin/rmiregistry && \
    unlink /usr/bin/servertool && \
    unlink /usr/bin/tnameserv && \
    unlink /usr/bin/unpack200 && \
    unlink /usr/lib/jvm-exports/jre && \
    unlink /usr/share/man/man1/java.1.gz && \
    unlink /usr/share/man/man1/jjs.1.gz && \
    unlink /usr/share/man/man1/keytool.1.gz && \
    unlink /usr/share/man/man1/orbd.1.gz && \
    unlink /usr/share/man/man1/pack200.1.gz && \
    unlink /usr/share/man/man1/policytool.1.gz && \
    unlink /usr/share/man/man1/rmid.1.gz && \
    unlink /usr/share/man/man1/rmiregistry.1.gz && \
    unlink /usr/share/man/man1/servertool.1.gz && \
    unlink /usr/share/man/man1/tnameserv.1.gz && \
    unlink /usr/share/man/man1/unpack200.1.gz && \
    chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    /usr/local/bin/fix-permissions /var/lib/jenkins && \
    /usr/local/bin/fix-permissions /var/log

VOLUME ["/var/lib/jenkins"]

USER 1001
ENTRYPOINT []
CMD ["/usr/libexec/s2i/run"]
```