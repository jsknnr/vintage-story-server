#!/bin/bash
set -e

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Function to handle shutdown
shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    supervisorctl stop all
}

# Set our trap for sigterm
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat ${VINTAGE_STORY_PATH}/image_version)
MAINTAINER=$(cat ${VINTAGE_STORY_PATH}/image_maintainer)
EXPECTED_FS_PERMS=$(cat ${VINTAGE_STORY_PATH}/expected_filesystem_permissions)

echo "$(timestamp) INFO: Launching Vintage Story dedicatged server image ${IMAGE_VERSION} by ${MAINTAINER}"

# Check for proper filesystem permissions
echo "$(timestamp) INFO: Validating data directory filesystem permissions"
if ! touch "${VINTAGE_STORY_PATH}/data/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of ${VINTAGE_STORY_PATH}/data is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by ${EXPECTED_FS_PERMS}"
    echo "from your container host attempt the following command 'sudo chown -R ${EXPECTED_FS_PERMS} /your/vintage_story/data/directory'"
    echo ""
    exit 1
fi

rm "${VINTAGE_STORY_PATH}/data/test"

# Get Vintage Story server binaries
if ! [ -f "${VINTAGE_STORY_PATH}/server/VERSION" ]; then
    echo "$(timestamp) INFO: Downloading Vintage Story server version ${GAME_VERSION} from ${GAME_BRANCH}"
    wget https://cdn.vintagestory.at/gamefiles/${GAME_BRANCH,,}/vs_server_linux-x64_${GAME_VERSION}.tar.gz
    tar xzf vs_server_linux-x64_${GAME_VERSION}.tar.gz -C "${VINTAGE_STORY_PATH}/server"
    echo "${GAME_VERSION}" > "${VINTAGE_STORY_PATH}/server/VERSION"
    rm -f vs_server_linux-x64_${GAME_VERSION}.tar.gz
elif [ $(cat ${VINTAGE_STORY_PATH}/server/VERSION) != "$GAME_VERSION" ]; then
    echo "$(timestamp) INFO: Current Vintage Story server version does not match version ${GAME_VERSION}, updating"
    echo "$(timestamp) INFO: Cleaning up previous Vintage Story installation..."
    rm -rfv ${VINTAGE_STORY_PATH}/server/*
    wget https://cdn.vintagestory.at/gamefiles/${GAME_BRANCH,,}/vs_server_linux-x64_${GAME_VERSION}.tar.gz
    tar xzf vs_server_linux-x64_${GAME_VERSION}.tar.gz -C ${VINTAGE_STORY_PATH}/server
    echo "${GAME_VERSION}" > ${VINTAGE_STORY_PATH}/server/VERSION
    rm -f vs_server_linux-x64_${GAME_VERSION}.tar.gz
else
    echo "$(timestamp) INFO: Vintage Story server version ${GAME_VERSION} already present"
fi

# Set backup schedule
echo "$(timestamp) INFO: Setting backup CRON schedule as ${BACKUP_CRON_SCHEDULE}"
echo "${BACKUP_CRON_SCHEDULE} ${VINTAGE_STORY_PATH}/backup.sh" > ${VINTAGE_STORY_PATH}/backup_crontab

# Check if we need to build a serverconfig.json file
# If we are running in Kubernetes this isn't used as we just expect a ConfigMap
if [ ! -f "${VINTAGE_STORY_PATH}/data/serverconfig.json" ]; then
    echo "$(timestamp) INFO: serverconfig.json not found at ${VINTAGE_STORY_PATH}/data/serverconfig.json"
    echo "$(timestamp) INFO: Generating new serverconfig.json"
    ${VINTAGE_STORY_PATH}/build_serverconfig.sh
else
    echo "$(timestamp) INFO: Found serverconfig.json at ${VINTAGE_STORY_PATH}/data/serverconfig.json"
fi

# Start Supervisor to manager VintageStoryServer and Backup processes
echo "$(timestamp) INFO: Starting Supervisor"
supervisord -c ${VINTAGE_STORY_PATH}/supervisord.conf &

# Hold us open
wait $!
