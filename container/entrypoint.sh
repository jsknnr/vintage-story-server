#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Function to handle shutdown
shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    kill $VS_PID
}

# Set our trap
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat ${VINTAGE_STORY_PATH}/image_version)
MAINTAINER=$(cat ${VINTAGE_STORY_PATH}/image_maintainer)
EXPECTED_FS_PERMS=$(cat ${VINTAGE_STORY_PATH}/expected_filesystem_permissions)

# Set .net path
export PATH=$PATH:$DOTNET_PATH

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
    echo "$(timestamp) INFO: Downloading Vintage Story server version ${GAME_VERSION}"
    wget https://cdn.vintagestory.at/gamefiles/${GAME_BRANCH,,}/vs_server_linux-x64_${GAME_VERSION}.tar.gz
    tar xzf vs_server_linux-x64_${GAME_VERSION}.tar.gz -C "${VINTAGE_STORY_PATH}/server"
    echo "${GAME_VERSION}" > "${VINTAGE_STORY_PATH}/server/VERSION"
elif [ $(cat ${VINTAGE_STORY_PATH}/server/VERSION) != "$GAME_VERSION" ]; then
    echo "$(timestamp) INFO: Current Vintage Story server version does not match version ${GAME_VERSION}, updating"
    wget https://cdn.vintagestory.at/gamefiles/stable/vs_server_linux-x64_${GAME_VERSION}.tar.gz
    rm -rf "${VINTAGE_STORY_PATH}/server/*"
    tar xzf vs_server_linux-x64_${GAME_VERSION}.tar.gz -C "${VINTAGE_STORY_PATH}/server"
    echo "${GAME_VERSION}" > "${VINTAGE_STORY_PATH}/server/VERSION"
else
    echo "$(timestamp) INFO: Vintage Story server version ${GAME_VERSION} already present"
fi

# Launch Vintage Story
echo "$(timestamp) INFO: Starting Vintage Story server..."
nohup dotnet "${VINTAGE_STORY_PATH}/server/VintagestoryServer.dll" --dataPath /home/vintagestory/data > /dev/stdout 2>&1 &

# Grab Vintage Story PID
VS_PID=$!

# Keep us open
wait $VS_PID

# Handle post sigterm so we can exit cleanly
tail --pid=$VS_PID -f /dev/null
