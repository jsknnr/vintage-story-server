# vintage-story-server

[![Static Badge](https://img.shields.io/badge/DockerHub-blue)](https://hub.docker.com/r/sknnr/vintage-story-server) ![Docker Pulls](https://img.shields.io/docker/pulls/sknnr/vintage-story-server) [![Static Badge](https://img.shields.io/badge/GitHub-green)](https://github.com/jsknnr/vintage-story-server) ![GitHub Repo stars](https://img.shields.io/github/stars/jsknnr/vintage-story-server)


Run Vintage Story dedicated server in a container. Optionally includes helm chart for running in Kubernetes.

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.
## Usage

The processes within the container do **NOT** run as root. Everything runs as the user vintagestory (gid:10000/uid:10000 by default). If you exec into the container, you will drop into `/home/vintagestory` as the vintagestory user. Persistent volumes should be mounted to `/home/vintagestory/server/` for server binaries and `/home/vintagestory/data` for persistent data and be owned by 10000:10000. 

If you absolutely require to run the process in the container as a gid/uid other than 10000, you can build your own image based on my dockerfile.

### serverconfig.json
I decided to not parameterize the serverconfig.json. There are just too many configuration options and I am feeling lazy today. So you can either mount your own config file into the container or modify the serverconfig.json file from the volume you are mounting into the container. The file should be owned by 10000:10000. 

Example of modifying the config file:
```bash
sudo vi /path/to/vintagestory/data/volume/serverconfig.json # use whatever text editor you like
# make your changes and save
sudo chown 10000:10000 /path/to/vintagestory/data/volume/serverconfig.json
```

Regardless of where the volume lives on the container host, the `serverconfig.json` needs to exist in the container at `/home/vintagestory/data/serverconfig.json`

There is an example of the config file in this repo under the container directory.

I will probably parameterize this in the future.

### Ports

If you want to change the port, you have to do this in the serverconfig.json file

| Port | Protocol | Default |
| ---- | -------- | ------- |
| Game Port | UDP | 42420 |

### Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| GAME_VERSION | Version of Vintage Story server to run | 1.19.8 | False |

### Docker

To run the container in Docker, run the following command:

```bash
docker run \
  --detach \
  --name vintage-story \
  --mount type=volume,source=vintage-story-data,target=/home/vintagestory/data \
  --mount type=volume,source=vintage-story-server,target=/home/vintagestory/server \
  --publish 42420:42420/udp \
  --env=GAME_VERSION='1.19.8' \
  sknnr/vintage-story-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` file out of the `container` directory to your local machine. Edit the compose file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains the compose and the env files, simply run:

```bash
docker-compose up -d
```

To bring the container down:

```bash
docker-compose down
```

compose.yaml file:
```yaml
version: '3'
services:
  enshrouded:
    image: sknnr/vintage-story-server:latest
    ports:
      - "42420:42420/udp"
    environment:
      - GAME_VERSION='1.19.8'
    volumes:
      - vintage-story-data:/home/vintagestory/data
      - vintage-story-server:/home/vintagestory/server
volumes:
  vintage-story-data:
  vintage-story-server:
```

### Podman

To run the container in Podman, run the following command:

```bash
podman run \
  --detach \
  --name vintage-story \
  --mount type=volume,source=vintage-story-data,target=/home/vintagestory/data \
  --mount type=volume,source=vintage-story-server,target=/home/vintagestory/server \
  --publish 42420:42420/udp \
  --env=GAME_VERSION='1.19.8' \
  docker.io/sknnr/vintage-story-server:latest
```

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.
