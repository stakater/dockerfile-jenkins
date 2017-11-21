# dockerfile-jenkins

dockerfile for jenkins

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

## References

- old fabric8 jenkins image: `https://github.com/fabric8io/jenkins-docker`
- current fabric8 jenkins image: `https://github.com/openshift/jenkins` & `https://github.com/fabric8io/openshift-jenkins-s2i-config`
- base jenkins docker image: `https://github.com/jenkinsci/docker/blob/master/Dockerfile-alpine`

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