FROM stakater/oracle-jdk:8u152-alpine-3.7

MAINTAINER Stakater Team

## Arguments

ARG USER=jenkins
ARG GROUP=jenkins
# why 386? Please read: https://github.com/jenkinsci/docker/issues/112#issuecomment-228553691
ARG UID=386
ARG GID=386
ARG HTTP_PORT=8080
ARG AGENT_PORT=50000
ARG JENKINS_VERSION=2.95
# This can be used to customize where jenkins.war get downloaded from:
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war
ARG INSTALL_PLUGINS=ace-editor:1.1,async-http-client:1.7.24.1,ant:1.5,antisamy-markup-formatter:1.5,ansicolor:0.5.2,authentication-tokens:1.3,blueocean-autofavorite:1.0.0,blueocean-commons:1.3.5,blueocean-config:1.3.5,blueocean-dashboard:1.3.5,blueocean-display-url:2.1.0,blueocean-events:1.3.5,blueocean-git-pipeline:1.3.5,blueocean-github-pipeline:1.3.5,blueocean-i18n:1.3.5,blueocean-jwt:1.3.5,blueocean-personalization:1.3.5,blueocean-pipeline-api-impl:1.3.5,blueocean-pipeline-editor:1.3.5,blueocean-pipeline-scm-api:1.3.5,blueocean-rest-impl:1.3.5,blueocean-rest:1.3.5,blueocean-web:1.3.5,blueocean:1.3.5,bouncycastle-api:2.16.1,branch-api:2.0.11,build-timeout:1.18,cloudbees-folder:6.1.2,credentials-binding:1.13,credentials:2.1.14,display-url-api:2.1.0,docker-commons:1.8,docker-workflow:1.12,dockerhub-notification:2.2.0,durable-task:1.14,email-ext:2.58,embeddable-build-status:1.9,external-monitor-job:1.7,favorite:2.3.0,ghprb:1.39.0,git-client:2.5.0,git-server:1.7,git:3.6.0,github-api:1.86,github-branch-source:2.2.3,github-issues:1.2.2,github-oauth:0.27,github-organization-folder:1.6,github-pr-coverage-status:1.8.1,github-pullrequest:0.1.0-rc24,github:1.28.0,gitlab-merge-request-jenkins:2.0.0,gitlab-oauth:1.0.9,gitlab-plugin:1.4.6,google-login:1.3,gradle:1.27.1,gravatar:2.1,handlebars:1.1.1,icon-shim:2.0.3,jackson2-api:2.7.3,jquery-detached:1.2.1,junit:1.21,kerberos-sso:1.3,kubernetes:1.5,ldap:1.16,lockable-resources:2.0,mailer:1.20,mapdb-api:1.0.9.0,mask-passwords:2.10.1,matrix-auth:1.7,matrix-project:1.11,mercurial:2.0,metrics:3.1.2.10,momentjs:1.1.1,multiple-scms:0.6,nodejs:1.2.4,oauth-credentials:0.3,oic-auth:1.0,openid:2.2,openid4java:0.9.8.0,pam-auth:1.3,pipeline-build-step:2.5.1,pipeline-github-lib:1.0,pipeline-githubnotify-step:1.0.2,pipeline-graph-analysis:1.5,pipeline-input-step:2.8,pipeline-milestone-step:1.3.1,pipeline-model-api:1.2,pipeline-model-declarative-agent:1.1.1,pipeline-model-definition:1.2,pipeline-model-extensions:1.2,pipeline-rest-api:2.8,pipeline-stage-step:2.2,pipeline-stage-tags-metadata:1.2,pipeline-stage-view:2.8,pipeline-utility-steps:1.3.0,plain-credentials:1.4,pubsub-light:1.12,resource-disposer:0.6,scm-api:2.2.2,script-security:1.39,sse-gateway:1.15,ssh-agent:1.15,ssh-credentials:1.13,ssh-slaves:1.20,structs:1.10,subversion:2.9,timestamper:1.8.8,token-macro:2.1,url-auth-sso:1.0,updatebot:1.0.10,variant:1.1,windows-slaves:1.3.1,workflow-aggregator:2.5,workflow-api:2.20,workflow-basic-steps:2.6,workflow-cps-global-lib:2.8,workflow-cps:2.39,workflow-durable-task-step:2.13,workflow-job:2.14.1,workflow-multibranch:2.16,workflow-remote-loader:1.4,workflow-scm-step:2.6,workflow-step-api:2.12,workflow-support:2.14,ws-cleanup:0.33

## Environment Variables

ENV JENKINS_USER ${USER}
ENV INSTALL_PLUGINS ${INSTALL_PLUGINS}
ENV IMAGE_CONFIG_DIR /usr/local/bin
ENV JENKINS_WAR_PATH /usr/share/jenkins
ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT ${AGENT_PORT}
# jenkins version being bundled in this docker image
ENV JENKINS_VERSION ${JENKINS_VERSION}
ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL https://updates.jenkins.io/experimental
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

RUN apk add --no-cache git openssh-client curl unzip bash ttf-dejavu coreutils gettext

# Jenkins is run with USER `jenkins`, UID = 386
# If you bind mount a volume from the host or a data container,
# ensure you use the same UID; and then things will work happily!
RUN addgroup -g ${GID} ${GROUP} \
    && adduser -h "$JENKINS_HOME" -u ${UID} -G ${GROUP} -s /bin/bash -D ${USER}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

## This is used to modify the jenkins slave agent port to 5000 as specified in JENKINS_SLAVE_AGENT_PORT env
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o ${JENKINS_WAR_PATH}/jenkins.war

## Expose

# for main web interface:
EXPOSE ${HTTP_PORT}
# will be used by attached slave agents:
EXPOSE ${AGENT_PORT}

COPY ./contrib ${IMAGE_CONFIG_DIR}

# Make daemon service dir for jenkins and place file
# It will be started and maintained by the base image
RUN mkdir -p /etc/service/jenkins
COPY ./contrib/run.sh /etc/service/jenkins/run
