FROM jenkins/jenkins:2.90-alpine

MAINTAINER Stakater Team

COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt