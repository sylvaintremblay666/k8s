#!/bin/sh

set -e

CONFIG_FILE="/go/bin/scollector.toml"

# Set OPTIONS
if [ "X${OPTIONS}" == "X" ]; then
    OPTIONS="-logtostderr -m"
fi
if echo "${DEBUG}" | grep -i "^true$" >/dev/null; then
    OPTIONS="${OPTIONS} -d"
fi

# Set defaults
export SC_CONF_FullHost=${SC_CONF_FullHost:-true}
if [ "X${SC_CONF_Hostname}" == "X" ] && [ "X${HOST}" != "X" ]; then
    export SC_CONF_Hostname="${HOST}"
fi
export SC_CONF_DisableSelf=${SC_CONF_DisableSelf:-true}
export SC_CONF_Freq=${SC_CONF_Freq:-60}

# Add Container details in tags
CGROUP_FILE="/proc/self/cgroup"
SC_CONF_TAG_container_id="$(cat ${CGROUP_FILE} | grep ".*/docker/[0-9a-f][0-9a-f]*" | sed 's|^.*/docker/\([0-9a-f][0-9a-f]*\)$|\1|' | head -n 1)"
if [ "X${SC_CONF_TAG_container_id}" == "X" ]; then
    SC_CONF_TAG_container_id="$(cat ${CGROUP_FILE} | grep ".*/system.slice/docker-[0-9a-f][0-9a-f]*.scope" | sed 's|^.*/system.slice/docker-\([0-9a-f][0-9a-f]*\).scope$|\1|' | head -n 1)"
fi
if [ "X${SC_CONF_TAG_container_id}" == "X" ]; then
    SC_CONF_TAG_container_id="$(cat ${CGROUP_FILE} | grep ".*/lxc/[0-9a-f][0-9a-f]*" | sed 's|^.*/lxc/\([0-9a-f][0-9a-f]*\)$|\1|' | head -n 1)"
fi

if [ "X${SC_CONF_TAG_container_id}" != "X" ]; then
    SC_CONF_TAG_machine_name="$(hostname)"
    export SC_CONF_TAG_container_id
    export SC_CONF_TAG_machine_name
fi

# Validate mandatory arguments
if [ "X${SC_CONF_Host}" == "X" ]; then
    echo "Env variable 'SC_CONF_Host' missing - OpenTSDB / Bosun host not configured. Aborting!"
    exit 1
fi

# Generate config file
rm -f ${CONFIG_FILE}
if [ ! -e ${CONFIG_FILE} ]; then
    touch ${CONFIG_FILE}
    NON_STRING_CONF="$(echo -e "FullHost\nDisableSelf\nFreq\nBatchSize\nMaxQueueLen")"

    for VAR in $(env); do
        if echo "$VAR" | grep "^SC_CONF_TAG_" >/dev/null; then
            # Skip tag env variables
            continue
        fi
        if echo "$VAR" | grep "^SC_CONF_" >/dev/null; then
            SC_CONF_name=$(echo "$VAR" | sed -r 's/^SC_CONF_([^=]*)=.*/\1/' | sed 's/__/./g')
            SC_CONF_value=$(echo "$VAR" | sed -r "s/^[^=]*=(.*)/\1/")
            if echo "${NON_STRING_CONF}" | grep "^${SC_CONF_name}$" >/dev/null; then
                echo "${SC_CONF_name} = ${SC_CONF_value}" >> ${CONFIG_FILE}
            else
                echo "${SC_CONF_name} = \"${SC_CONF_value}\"" >> ${CONFIG_FILE}
            fi
        fi
    done
    # Generate Tags
    if env | grep "^SC_CONF_TAG_" >/dev/null; then
        echo '' >> ${CONFIG_FILE}
        echo '[Tags]' >> ${CONFIG_FILE}
        for VAR in $(env); do
            if echo "$VAR" | grep "^SC_CONF_TAG_" >/dev/null; then
              SC_CONF_TAG_name=$(echo "$VAR" | sed -r 's/^SC_CONF_TAG_([^=]*)=.*/\1/' | sed 's/__/./g')
              SC_CONF_TAG_value=$(echo "$VAR" | sed -r "s/^[^=]*=(.*)/\1/")
              if echo "${NON_STRING_CONF}" | grep "^${SC_CONF_TAG_name}$" >/dev/null; then
                  echo "${SC_CONF_TAG_name} = ${SC_CONF_TAG_value}" >> ${CONFIG_FILE}
              else
                  echo "${SC_CONF_TAG_name} = \"${SC_CONF_TAG_value}\"" >> ${CONFIG_FILE}
              fi
            fi
        done
    fi
fi

# RUN scollector
exec /go/bin/scollector ${OPTIONS}
