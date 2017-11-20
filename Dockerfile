FROM jenkins/jenkins:2.90-alpine

MAINTAINER Stakater Team

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN xargs /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt