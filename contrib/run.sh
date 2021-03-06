#!/bin/bash
# set -ex will print commands

#
# This script runs the Jenkins server inside the Docker container.
#
# It copies the configuration and plugins from /opt/openshift/configuration to
# ${JENKINS_HOME}.
#
# It also sets the admin password to ${JENKINS_PASSWORD}.
#

## source: https://github.com/openshift/jenkins/blob/master/2/contrib/s2i/run

source /usr/local/bin/jenkins-common.sh
source /usr/local/bin/kube-slave-common.sh

shopt -s dotglob

function update_admin_password() {
    sed -i "s,<passwordHash>.*</passwordHash>,<passwordHash>$new_password_hash</passwordHash>,g" "${JENKINS_HOME}/users/admin/config.xml"
    echo $new_password_hash > ${JENKINS_HOME}/password
}

function create_jenkins_config_xml() {
  # copy the default configuration from the image into the jenkins config path (which should be a volume for persistence).
  if [ ! -f "${image_config_path}" ]; then
    # If it contains a template (tpl) file, we can do additional manipulations to customize
    # the configuration.
    if [ -f "${image_config_path}.tpl" ]; then
      export KUBERNETES_CONFIG=$(generate_kubernetes_config)
      echo "Generating kubernetes-plugin configuration (${image_config_path}.tpl) ..."
      envsubst < "${image_config_path}.tpl" > "${image_config_path}"
    fi
  fi
}

function create_jenkins_credentials_xml() {
  if [ ! -f "${image_config_dir}/credentials.xml" ]; then
    if [ -f "${image_config_dir}/credentials.xml.tpl" ]; then
      if [ ! -z "${KUBERNETES_CONFIG}" ]; then
        echo "Generating kubernetes-plugin credentials (${JENKINS_HOME}/credentials.xml.tpl) ..."
        export KUBERNETES_CREDENTIALS=$(generate_kubernetes_credentials)
      fi
      # Fix the envsubst trying to substitute the $Hash inside credentials.xml
      export Hash="\$Hash"
      envsubst < "${image_config_dir}/credentials.xml.tpl" > "${image_config_dir}/credentials.xml"
    fi
  fi
}

function create_jenkins_config_from_templates() {
    find ${image_config_dir} -type f -name "*.tpl" -print0 | while IFS= read -r -d '' template_path; do
        local target_path=${template_path%.tpl}
        if [[ ! -f "${target_path}" ]]; then
            if [[ "${target_path}" == "${image_config_path}" ]]; then
                create_jenkins_config_xml
            elif [[ "${target_path}" == "${image_config_dir}/credentials.xml" ]]; then
                create_jenkins_credentials_xml
            else
                # Allow usage of environment variables in templated files, e.g. ${DOLLAR}MY_VAR is replaced by $MY_VAR
                DOLLAR='$' envsubst < "${template_path}" > "${target_path}"
            fi
        fi
    done
}

function install_plugins() {
  # If the INSTALL_PLUGINS variable is populated, then attempt to install
  # those plugins before copying them over to JENKINS_HOME
  # The format of the INSTALL_PLUGINS variable is a comma-separated list
  # of pluginId:pluginVersion strings
  if [[ -n "${INSTALL_PLUGINS:-}" ]]; then
    echo "Installing additional plugins: ${INSTALL_PLUGINS} ..."

    # Create a temporary file in the format of plugins.txt
    plugins_file=$(mktemp)
    IFS=',' read -ra plugins <<< "${INSTALL_PLUGINS}"
    for plugin in "${plugins[@]}"; do
      # echo "${plugin}"
      echo "${plugin}" >> "${plugins_file}"
    done

    echo ${plugins_file}
    cat ${plugins_file}

    # Call install plugins with the temporary file
    echo "Calling install-plugins.sh"
    # /usr/local/bin/install-plugins.sh "${plugins_file}"
    /usr/local/bin/install-plugins.sh $(cat ${plugins_file} | tr '\n' ' ')
  fi

  if [ "$(ls -A /usr/share/jenkins/ref/plugins 2>/dev/null)" ]; then
    mkdir -p ${JENKINS_HOME}/plugins
    echo "Copying $(ls /usr/share/jenkins/ref/plugins | wc -l) Jenkins plugins to ${JENKINS_HOME}/plugins/ ..."
    cp -r /usr/share/jenkins/ref/plugins/* ${JENKINS_HOME}/plugins/
    rm -rf /usr/share/jenkins/ref/plugins/
  fi

# Copy external plugins
  if [ "$(ls -A ${IMAGE_CONFIG_DIR}/plugins 2>/dev/null)" ]; then
    echo "Copying $(ls ${IMAGE_CONFIG_DIR}/plugins/ | wc -l) Jenkins plugins to ${JENKINS_HOME}/plugins/ ..."
    cp -r ${IMAGE_CONFIG_DIR}/plugins/* ${JENKINS_HOME}/plugins/
    rm -rf ${IMAGE_CONFIG_DIR}/plugins/
  fi
}

# echo $JAVA_HOME
# java -version
# java -d64 -version # If its not 64 JVM then it will say; This Java instance does not support a 64-bit JVM. Please install the desired version.

image_config_dir=${IMAGE_CONFIG_DIR}
image_config_path="${image_config_dir}/config.xml"


CONTAINER_MEMORY_IN_BYTES=`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`
DEFAULT_MEMORY_CEILING=$((2**40-1))
if [ "${CONTAINER_MEMORY_IN_BYTES}" -lt "${DEFAULT_MEMORY_CEILING}" ]; then

    if [ -z $CONTAINER_HEAP_PERCENT ]; then
        CONTAINER_HEAP_PERCENT=0.50
    fi

    CONTAINER_MEMORY_IN_MB=$((${CONTAINER_MEMORY_IN_BYTES}/1024**2))
    #if machine has 4GB or less, meaning max heap of 2GB given current default, force use of 32bit to save space unless user
    #specifically want to force 64bit
    HEAP_LIMIT_FOR_32BIT=$((2**32-1))
    HEAP_LIMIT_FOR_32BIT_IN_MB=$((${HEAP_LIMIT_FOR_32BIT}/1024**2))
    CONTAINER_HEAP_MAX=$(echo "${CONTAINER_MEMORY_IN_MB} ${CONTAINER_HEAP_PERCENT}" | awk '{ printf "%d", $1 * $2 }')

    JAVA_MAX_HEAP_PARAM="-Xmx${CONTAINER_HEAP_MAX}m"
    if [ -z $CONTAINER_INITIAL_PERCENT ]; then
      CONTAINER_INITIAL_PERCENT=0.07
    fi
    CONTAINER_INITIAL_HEAP=$(echo "${CONTAINER_HEAP_MAX} ${CONTAINER_INITIAL_PERCENT}" | awk '{ printf "%d", $1 * $2 }')
    JAVA_INITIAL_HEAP_PARAM="-Xms${CONTAINER_INITIAL_HEAP}m"
fi

if [ -z "$JAVA_GC_OPTS" ]; then
    # We no longer set MaxMetaspaceSize because the JVM should expand metaspace until it reaches the container limit.
    # See http://hg.openjdk.java.net/jdk8u/jdk8u/hotspot/file/4dd24f4ca140/src/share/vm/memory/metaspace.cpp#l1470
    JAVA_GC_OPTS="-XX:+UseParallelGC -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90"
fi

if [ ! -z "${USE_JAVA_DIAGNOSTICS}" ]; then
    JAVA_DIAGNOSTICS="-XX:NativeMemoryTracking=summary -XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UnlockDiagnosticVMOptions"
fi

if [ ! -z "${CONTAINER_CORE_LIMIT}" ]; then
    JAVA_CORE_LIMIT="-XX:ParallelGCThreads=${CONTAINER_CORE_LIMIT} -Djava.util.concurrent.ForkJoinPool.common.parallelism=${CONTAINER_CORE_LIMT} -XX:CICompilerCount=2"
fi

if [ -z "${JAVA_OPTS}" ]; then
    JAVA_OPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -Dsun.zip.disableMemoryMapping=true"
fi

# Since OpenShift runs this Docker image under random user ID, we have to assign
# the 'jenkins' user name to this UID.
echo "Generating Password file"
generate_passwd_file

# Temporarily uncommited. How is this hardcoded if we provide $JENKINS_PASSWORD via config map?
mkdir /tmp/war

echo "Unzipping jenkins.war"
unzip -q ${JENKINS_WAR_PATH}/jenkins.war -d /tmp/war
if [ -e ${JENKINS_HOME}/password ]; then
 old_salt=$(cat ${JENKINS_HOME}/password | sed 's/:.*//')
fi
echo "Obfuscating new password"
new_password_hash=`obfuscate_password ${JENKINS_PASSWORD:-password} $old_salt`

#finish the move of the default logs dir, /var/log/jenkins, to the volume mount
mkdir -p ${JENKINS_HOME}/logs
ln -sf ${JENKINS_HOME}/logs /var/log/jenkins

echo "Checking {JENKINS_HOME}/configured"
if [ ! -e ${JENKINS_HOME}/configured ]; then
    # This container hasn't been configured yet
    create_jenkins_config_from_templates

    echo "Copying Jenkins configuration to ${JENKINS_HOME} ..."
    cp -r ${IMAGE_CONFIG_DIR}/configuration/* ${JENKINS_HOME}

    echo "Calling install_plugins"
    install_plugins

    echo "Creating initial Jenkins 'admin' user ..."
    update_admin_password

    touch ${JENKINS_HOME}/configured
else
  if [ ! -z "${OVERRIDE_PV_CONFIG_WITH_IMAGE_CONFIG}" ]; then
    echo "Overriding jenkins config.xml stored in ${JENKINS_HOME}/config.xml"
    rm -f ${JENKINS_HOME}/config.xml

    create_jenkins_config_xml

    cp -r ${image_config_path} ${JENKINS_HOME}
  fi

  if [ ! -z "${OVERRIDE_PV_PLUGINS_WITH_IMAGE_PLUGINS}" ]; then
    echo "Overriding plugins stored in ${JENKINS_HOME}/plugins"
    rm -rf ${JENKINS_HOME}/plugins

    echo "Installing plugins"
    install_plugins
  fi
fi

echo "Checking {JENKINS_HOME}/password"
if [ -e ${JENKINS_HOME}/password ]; then
  # if the password environment variable has changed, update the jenkins config.
  # we don't want to just blindly do this on startup because the user might change their password via
  # the jenkins ui, so we only want to do this if the env variable has been explicitly modified from
  # the original value.
  old_password_hash=`cat ${JENKINS_HOME}/password`
  if [ $old_password_hash != $new_password_hash ]; then
      echo "Detected password environment variable change, updating Jenkins configuration ..."
      update_admin_password
  fi
fi

echo "Checking {CONFIG_PATH}.tpl"
if [ -f "${CONFIG_PATH}.tpl" -a ! -f "${CONFIG_PATH}" ]; then
  echo "Processing Jenkins configuration (${CONFIG_PATH}.tpl) ..."
  envsubst < "${CONFIG_PATH}.tpl" > "${CONFIG_PATH}"
fi

echo "Removing war file"
rm -rf /tmp/war

# TODO: @Waseem: what is this?
# default log rotation in /etc/logrotate.d/jenkins handles /var/log/jenkins/access_log
if [ ! -z "${OPENSHIFT_USE_ACCESS_LOG}" ]; then
    JENKINS_ACCESSLOG="--accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/jenkins/access_log"
fi

## The Jenkins monitoring plugin stores its data in /var/lib/jenkins/monitoring/<hostName>.
## Since the pod name changes everytime there is a deployment, any trending data is lost over
## re-deployments. We force the application name to allow for historical data collection.
##
JENKINS_SERVICE_NAME=${JENKINS_SERVICE_NAME:-JENKINS}
JENKINS_SERVICE_NAME=`echo ${JENKINS_SERVICE_NAME} | tr '[a-z]' '[A-Z]' | tr '-' '_'`
JAVA_OPTS="${JAVA_OPTS} -Djavamelody.application-name=${JENKINS_SERVICE_NAME}"

# Own JENKINS_HOME
owner=`stat -c "%U:%G" "${JENKINS_HOME}"`
owner2=`stat -c "%U:%G" /usr/share/jenkins/`
if [ "${owner}" != "${JENKINS_USER}:${JENKINS_USER}" -a "${owner2}" != "${JENKINS_USER}:${JENKINS_USER}" ]; then
  echo "Running Chown"
  chown -R ${JENKINS_USER}:${JENKINS_USER} ${JENKINS_HOME} /usr/share/jenkins/ref
fi

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  #Run via JENKINS_USER
  echo "Running Jenkins now"
  su-exec ${JENKINS_USER} java $JAVA_GC_OPTS $JAVA_INITIAL_HEAP_PARAM $JAVA_MAX_HEAP_PARAM -Duser.home=${HOME} $JAVA_CORE_LIMIT $JAVA_DIAGNOSTICS $JAVA_OPTS -Dfile.encoding=UTF8 -jar ${JENKINS_WAR_PATH}/jenkins.war $JENKINS_OPTS $JENKINS_ACCESSLOG "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
