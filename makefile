# This is for local development and testing of the container image and not intended to be used to run the server for play

# Image values
REGISTRY := "localhost"
IMAGE := "vintage-story-dev"
IMAGE_REF := $(REGISTRY)/$(IMAGE)
GIT_HASH := $(shell git rev-parse --short=8 HEAD)

# Podman Options
CONTAINER_NAME := "vintage-story-dev"
SERVER_VOLUME_NAME := "vintage-story-server"
DATA_VOLUME_NAME := "vintage-story-data"
PODMAN_BUILD_OPTS := --build-arg="IMAGE_VERSION=$(GIT_HASH)-devel" --format docker -f ./container/Containerfile
PODMAN_RUN_OPTS_NO_CONFIG := --name $(CONTAINER_NAME) --env=GAME_VERSION="1.19.8" --env=GAME_BRANCH="stable" --env=port=52520 --env=mapSizeX="100000" --env=mapSizeZ=100000 --env=serverName="dev server test" --env=password="thisisapassword" --env=advertiseServer=true --env=snowAccum="true" --env=seed="ForWhomeTheBellTolls" --env=worldName="Testing" --env=graceTimer="3" --env=startupCommands="/op sknnr \n/moddb install playercorpse" --stop-timeout 90 -d --mount type=volume,source=$(SERVER_VOLUME_NAME),target=/home/vintagestory/server --mount type=volume,source=$(DATA_VOLUME_NAME),target=/home/vintagestory/data
PODMAN_RUN_OPTS_MOUNTED_CONFIG := --name $(CONTAINER_NAME) --env=GAME_VERSION="1.19.8" --env=GAME_BRANCH="stable" --stop-timeout 90 -d --mount type=volume,source=$(SERVER_VOLUME_NAME),target=/home/vintagestory/server --mount type=volume,source=$(DATA_VOLUME_NAME),target=/home/vintagestory/data --mount type=bind,source=./container/example_serverconfig.json,target=/home/vintagestory/data/serverconfig.json

# Makefile targets
.PHONY: build run run-no-vol clean-all clean-build clean-volume clean-image

build:
	podman build $(PODMAN_BUILD_OPTS) -t $(IMAGE_REF):latest ./container

run-no-config:
	podman volume create $(SERVER_VOLUME_NAME)
	podman volume create $(DATA_VOLUME_NAME)
	podman run $(PODMAN_RUN_OPTS_NO_CONFIG) $(IMAGE_REF):latest

run-mounted-config:
	podman volume create $(SERVER_VOLUME_NAME)
	podman volume create $(DATA_VOLUME_NAME)
	podman run $(PODMAN_RUN_OPTS_MOUNTED_CONFIG) $(IMAGE_REF):latest

# Clean all artifacts
clean-all:
	podman rm -f $(CONTAINER_NAME)
	podman rmi -f $(IMAGE_REF):latest
	podman volume rm $(SERVER_VOLUME_NAME)
	podman volume rm $(DATA_VOLUME_NAME)

# Clean container and volume
clean-build:
	podman rm -f $(CONTAINER_NAME)
	podman volume rm $(SERVER_VOLUME_NAME)
	podman volume rm $(DATA_VOLUME_NAME)

# Clean container
clean-container:
	podman rm -f $(CONTAINER_NAME)

# Clean volume
clean-volume:
	podman volume rm $(SERVER_VOLUME_NAME)
	podman volume rm $(DATA_VOLUME_NAME)

# Clean image
clean-image:
	podman rmi -f $(IMAGE_REF):latest
