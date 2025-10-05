# vintage-story-server
 
[![Static Badge](https://img.shields.io/badge/DockerHub-blue)](https://hub.docker.com/r/sknnr/vintage-story-server) ![Docker Pulls](https://img.shields.io/docker/pulls/sknnr/vintage-story-server) [![Static Badge](https://img.shields.io/badge/GitHub-green)](https://github.com/jsknnr/vintage-story-server) ![GitHub Repo stars](https://img.shields.io/github/stars/jsknnr/vintage-story-server)

Run Vintage Story dedicated server in a container. Optionally includes helm chart for running in Kubernetes.

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.

## Managing the Container

The processes within the container do **NOT** run as root. Everything runs as the user vintagestory (gid:10000/uid:10000 by default). If you exec into the container, you will drop into `/home/vintagestory` as the vintagestory user. Persistent volumes should be mounted to `/home/vintagestory/server/` for server binaries and `/home/vintagestory/data` for persistent config, world save, and mod data.

If you absolutely require to run the process in the container as a gid/uid other than 10000, you can build your own image based on my dockerfile. Here is an example of how to do this.

### Updating Server
The image is capable of updating itself, but not automatically. If a new version is released, just update the `GAME_VERSION` variable to match the new version and when the container starts it will update to the new version.

### Restarting the Server
To restart the server it is safe to stop and start the container. The stop process will gracefully stop the Vintage Story server process and initiate a save before closing.

### Backups
By default the container will issue the server /genbackup command **daily**. The backups will be created at `/home/vintagestory/data/Backups`. By default this will run at 3 AM (03:00) **server time** which is typically UTC and keep 7 days worth of backups. To configure the schedule and the retention policy (days to keep), refer to [Environment Variables](#environment-variables)

Backups can be quite large. As part of the backup process, I use GZIP compression and create an archive of each backup file which ends up being around 1/4 of the original size in my tests. With that said, a days worth of backups done hourly could be well over 1GB per day. Keep that in mind.

### Mods
Server admins can install mods with server commands as documented [Here](https://wiki.vintagestory.at/Special:MyLanguage/List_of_server_commands#/moddb)
Additionally, you can manually install mods by dropping the mod zip file (do not unzip) in `data/Mods` either from within the container (search "how to exec into container") or if you have access to the volume outside of the container, you can do it that way as well. If a mod also has a config file, they are stored at `data/ModConfig`. If a mod is installed while the server is running, it will need restarted to take effect.

Any mod that changes world gen, such as [Terra Prety](https://mods.vintagestory.at/terraprety) or [Plains and Valleys](https://mods.vintagestory.at/plainsandvalleys), should be in the Mods directory before the server runs for the first time or weird things can happen to the world. Pre-provisioning the `Mods` directory inside the `data` volume and seeding it with the zip file is one option.

### Becoming a Server Admin
To grant the initial admin role to someone, you have 2 options:

1) You can to modify your `serverconfig.json` file parameter `"StartupCommands"` to something like `"StartupCommands": "/op playername"`.
2) You can exec into the container and use the interactive terminal:
  ```bash
  # docker
  docker exec -it my-vintage-story-container bash -c "supervisorctl fg vintagestory"
  # podman
  podman exec -it my-vintage-story-container -- bash -c "supervisorctl fg vintagestory"
  # kubernetes
  kubectl -n vintagestory exec -it deploy/vintage-story-server -- bash -c "supervisorctl fg vintagestory"
  ```
  From here you can run `/op playername` or any of the server terminal commands. I should note that you will not see the output as it is getting swallowed by supervisor. To see the output follow the container log in a separate terminal window, for example: `docker logs -f my-vintage-story-container`

### Manually Modifying Files Outside of the Container
Modifying files in a volume from outside of the container can modify permissions of the file and cause Vintage Story to not be able to read the file. If you do this, be sure to reset permissions on any file you add or modify in the file: `sudo chown 10000:10000 my_modified_or_added_file`

### Manually Modifying Files Inside of the Container and Using Vintage Story Admin Terminal
If you need to manually modify files it is best to do it from within the container. The container has `vim` as a text editor for modifying things like config files and `wget` to be able to download files from the internet. Here are a few examples:
```bash
# manually editing the serverconfig.json file from within the container and restarting the process
docker exec -it my-vintage-story-container bash
cd data
vi serverconfig.json
supervisorctl restart vintagestory
# manually downloading a mod from vintage story moddb
docker exec -it my-vintage-story-container bash
cd data/Mods
wget --content-disposition https://mods.vintagestory.at/download?fileid=21975
supervisorctl restart vintagestory
# accessing the Vintage Story admin terminal
docker exec -it my-vintage-story-container bash
supervisorctl fg vintagestory
/op playername
/moddb install playercorpse
/whitelist playername
# you can also gain access to the admin terminal directly
docker exec -it my-vintage-story-container bash -c "supervisorctl fg vintagestory"
```

### On Your Quest for the Perfect World
If you are like me, you spend a stupid amount of time generating worlds looking for the perfect one. There is an easier way to do this without recreating the whole container, especially if you use worldgen mods that must be loaded into `data/Mods` before the server process runs for the first time on a given world.
```bash
# exec into the container
docker exec -it my-vintage-story-container bash
# stop the server process
supervisorctl stop vintagestory
# delete your current save - this will not remove config files, backups, or mods that have already been downloaded
rm -f ./data/Saves/*
# start the server process
supervisorctl start vintagestory
# alternatively, here is a 1 liner
docker exec -it my-vintage-story-container bash -c "supervisorctl stop vintagestory && rm -f /home/vintagestory/data/Saves/* && supervisorctl start vintagestory"
# here is a 1 liner for kubernetes - make sure you set the correct namespace
kubectl -n vintagestory exec -it deploy/vintage-story-server -- bash -c 'supervisorctl stop vintagestory && rm -f /home/vintagestory/data/Saves/* && rm -rf /home/vintagestory/data/Cache/* && supervisorctl start vintagestory'
```
Now you can log back into your server and see if this is the world for you and your group.

## Running the Container

### Ports
Game Port is specified in serverconfig.json. Game versions > 1.19 UDP as well as TCP.

| Port      | Protocol | Default |
|-----------|----------|---------|
| Game Port | TCP & UDP | 42420   |


### Environment Variables

| Name                 | Description                                                                 | Default   | Required |
|----------------------|-----------------------------------------------------------------------------|-----------|----------|
| GAME_VERSION         | Version of Vintage Story server to run                                      | "1.21.2"  | False    |
| GAME_BRANCH          | Which branch to pull server files from, "stable" or "unstable"              | "stable"  | False    |
| REGENERATE_CONFIG    | If set to true, will regenerate serverconfig.json from environment variables even if there is an existing serverconfig.json | 'faslse' | False |
| BACKUP_CRON_SCHEDULE | When the backup script should run, expressed in a CRON format: [Example](https://cloud.google.com/scheduler/docs/configuring/cron-job-schedules#sample_schedules) Default is daily at 3 AM server time (typically UTC) | "0 3 * * *" | False    |
| BACKUP_RETENTION_DAYS | Number of days to keep backups (warning, backups can be quite large)                                             | 7         | False    |
| BACKUP_RETENTION_MINUTES | Number of minutes to keep backups. Useful for aggressive backup schedules. Only define minutes or days. Supersedes BACKUP_RETENTION_DAYS. | not defined | False |

### serverconfig.json
If you do not mount a serverconfig.json file into the container, then the container will build one for you.

Most of the settings for the server are in `serverconfig.json` which exists at `/home/vintagestory/data/serverconfig.json` in the container. You can supply your own serverconfig.json by mounting it into the container in the method of your choosing.

If the serverconfig.json file is not found during startup, the container will create one for you based on the variables you can define in [Server Config Environment Variables](#server-config-environment-variables)

An example of the serverconfig.json file can be found in the GitHub repo for this image [Here](https://github.com/jsknnr/vintage-story-server/blob/main/container/example_serverconfig.json)

If you do supply your own serverconfig.json file, pay particular attention to the paths in the config file like the path to the save file and where mods are stored.
The correct values for those paths can be found in the example linked above.

If you are mounting a serverconfig.json file into the container, make sure it has the correct permissions by modifying its user and group IDs to match the container:
```bash
sudo chown 10000:10000 /my/container/volume/path/data/serverconfig.json
```
Where `/my/container/volume/path/data` is the local path on your container host to where your serverconfig.json file is at that you wish to mount into the container.

### Server Config Environment Variables
These variables are **all optional** and only necessary if you aren't bringing your own serverconfig.json and would like the container to generate one for you.
If the container does not find a mounted serverconfig.json file, it will automatically begin the process of building one based on these variables. You only need to supply the variables you want to change.

With the exceptions of serverName and worldName, all of the defaults below are taken from an unmodified default survival world.

These variables only work when creating a new serverconfig.json, they do not modify an existing serverconfig.json (unless you are using the Kubernetes helm chart, then it will update the config map)

| Name                      | Description                                                                                                            | Default                                       |
|---------------------------|------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| serverName                | The name of the server                                                                                                 | "The Glorious Server"                         |
| serverDescription         | The description of the server                                                                                          | ""                                            |
| welcomeMessage            | The message that displays when joining the server                                                                      | "Welcome {0}, may you survive well and prosper" |
| advertiseServer           | Whether or not to advertise the server on the server list | true |
| port                      | The port the server should listen on                                                                                   | 42420 |
| maxPlayers                | Maximum number of concurrent players                                                                                   | 16                                            |
| password                  | Password protects the server if specified                                                                              | ""                                            |
| mapSizeX                  | World X (width) axis size in blocks                                                                                    | 1024000                                       |
| mapSizeY                  | World Y (height) axis size in blocks                                                                                   | 256                                           |
| mapSizeZ                  | World Z (length) axis size in blocks                                                                                   | 1024000                                       |
| serverLanguage            | Language for server                                                                                                    | "en"                                          |
| seed                      | Seed to use for world generation                                                                                       | ""                                            |
| worldName                 | Name of the world                                                                                                      | "Our Little World"                            |
| allowCreative             | Whether or not to allow creative mode                                                                                  | true                                          |
| playStyle                 | The game mode                                                                                                          | "surviveandbuild"                             |
| playStyleLangCode         | Should match game mode                                                                                                 | "preset-surviveandbuild"                      |
| gameMode                  | The value is slightly different but should match playStyle                                                             | "survival"                                    |
| startingClimate           | The climate region for initial spawn                                                                                   | "temperate"                                   |
| spawnRadius               | Radius in blocks to spawn within initial spawn area                                                                    | "50"                                          |
| graceTimer                | Number of days before monsters spawn                                                                                   | "0"                                           |
| deathPunishment           | Whether you keep your inventory or not when you die                                                                    | "drop"                                        |
| droppedItemsTimer         | Timer in seconds for how long your inventory remains in world on death                                                 | "600"                                         |
| seasons                   | Whether or not to enable seasons                                                                                       | "enabled"                                     |
| playerLives               | How many lives a player has (infinite is default [-1])                                                                 | "-1"                                          |
| lungCapacity              | How long you can hold your breath underwater in milliseconds                                                           | "40000"                                       |
| daysPerMonth              | How many days are in each game month                                                                                   | "9"                                           |
| harshWinters              | Whether or not survival is harder during the winter                                                                    | "true"                                        |
| blockGravity              | Which blocks fall without support                                                                                      | "sandgravel"                                  |
| caveIns                   | Causes unstable rock to collapse when mined                                                                            | "off"                                         |
| allowUndergroundFarming   | Whether or not you can grow surface crops deep underground                                                             | false                                         |
| bodyTemperatureResistance | The outside temperature player can withstand without clothing and dry                                                  | "0"                                           |
| creatureHostility         | How creatures react to player                                                                                          | "aggressive"                                  |
| creatureStrength          | How much damage a creature inflicts on player                                                                          | "1"                                           |
| playerHealthPoints        | Base health points player starts with                                                                                  | "15"                                          |
| playerHungerSpeed         | Base rate at which player gets hungry                                                                                  | "1"                                           |
| playerHealthRegenSpeed    | Base rate at which player recovers health                                                                              | "1"                                           |
| playerMoveSpeed           | Base rate at which player moves                                                                                        | "1.5"                                         |
| foodSpoilSpeed            | Base rate at which food spoils                                                                                         | "1"                                           |
| saplingGrowthRate         | Rate at which tree saplings grow                                                                                       | "1"                                           |
| toolDurability            | How long tools last until breaking                                                                                     | "1"                                           |
| toolMiningSpeed           | How fast tools break blocks                                                                                            | "1"                                           |
| propickNodeSearchRadius   | Block radius for prospecting pick node search mode                                                                     | "6"                                           |
| globalDepositSpawnRate    | Affects the spawn rate of all ores                                                                                     | "1"                                           |
| microblockChiseling       | Which blocks the chisel tool can carve                                                                                 | "stonewood"                                   |
| allowCoordinatedHud       | Whether to allow the use of coordinated overlay                                                                        | true                                          |
| allowMap                  | Whether to allow use of world map                                                                                      | true                                          |
| colorAccurateWorldmap     | If activated, world map will display actual block colors                                                               | false                                         |
| loreContent               | Whether to generate lore and story related content                                                                     | true                                          |
| clutterObtainable         | Can the player obtain clutter blocks from ruins                                                                        | "ifrepaired"                                  |
| temporalStorms            | How often temporal storms should occur                                                                                 | "sometimes"                                   |
| temporalstormDurationMul  | How long temporal storms should last                                                                                   | "1"                                           |
| temporalStability         | Enable or disable temporal stability game mechanic                                                                     | true                                          |
| temporalRifts             | Whether or not temporal rifts are visible, invisible, or off                                                           | "visible"                                     |
| temporalGearRespawnUses   | How often you can use a temporal gear to reset your spawn point                                                        | "20"                                          |
| temporalStormSleeping     | Whether or not you can sleep during a temporal storm                                                                   | "0"                                           |
| worldClimate              | How climate distribution works, seasons are optimized for realistic                                                    | "realistic"                                   |
| landcover                 | Percentage of world that should be land vs ocean                                                                       | "0.975"                                           |
| oceanscale                | Percentage of ocean that should exist between land                                                                     | "5"                                           |
| upheavelCommonness        | How common geologic upheaval should be (produces large scale hilly terrain)                                            | "0.3"                                         |
| geologicActivity          | Undocumented but I believe affects lava flow                                                                           | "0.05"                                        |
| landformScale             | Shapes the terrain and determines where lakes, mountains, forests, etc are formed (larger value makes these landforms larger) | "1.0"                                         |
| worldEdge                 | What happens when a player crosses the edge of the world                                                               | "traversable"                                 |
| polarEquatorDistance      | Distance in blocks between a polar zone and an equator                                                                 | "100000"                                      |
| globalTemperature         | World overall temperature (normal is default which is 1)                                                               | "1"                                           |
| globalPercipitation       | World overall precipitation                                                                                           | "1"                                           |
| globalForestation         | Amount of forests and shrubs to generate globally (default is normal which is value 0)                                 | "0"                                           |
| surfaceCopperDeposits     | How often copper should spawn on the surface                                                                           | "0.12"                                        |
| surfaceTinDeposits        | How often tin should spawn on the surface                                                                              | "0.007"                                       |
| snowAccum                 | Snow will accumulate on the ground in snowy weather at cold temperatures and water will freeze                         | "true"                                        |
| allowLandClaiming         | Allow players to claim land as theirs                                                                                  | true                                          |
| classExclusiveRecipes     | If enabled, some recipes are only available to certain classes                                                         | true                                          |
| auctionHouse              | Whether or not to allow global auction house at traders                                                                | true                                          |
| onlyWhitelisted           | Only allow players to connect if on white list, not sure how this works, just use a password                           | false                                         |
| whitelistMode             | Enable or disable WhiteList mode, set to 1 for off                                                                     | 1                                             |
| allowPvP                  | Whether or not players can hurt each other                                                                             | true                                          |
| allowFireSpread           | Whether or not to allow fire to spread when items are burning                                                          | true                                          |
| allowFallingBlocks        | Whether or not to allow blocks to fall                                                                                 | true                                          |
| startupCommands           | Server commands to run at server start, useful for granting initial admin rights, example "/op playername1 \n /op playername2". Multiple commands are separated with carriage return "\n" | ""                                            |

### Docker

To run the container in Docker, see the following examples.


#### Running with Docker and mounting a serverconfig.json file into the container
```bash
docker run \
  --detach \
  --name vintage-story \
  --mount type=volume,source=vintage-story-data,target=/home/vintagestory/data \
  --mount type=volume,source=vintage-story-server,target=/home/vintagestory/server \
  --mount type=bind,source=/my/local/path/to/serverconfig.json,target=/home/vintagestory/data/serverconfig.json \
  --publish 42420:42420/tcp \
  --publish 42420:42420/udp \
  --env=GAME_VERSION='1.21.2' \
  --env=GAME_BRANCH='stable' \
  sknnr/vintage-story-server:latest
```

#### Running with Docker and letting container build a serverconfig.json for you
```bash
docker run \
  --detach \
  --name vintage-story \
  --mount type=volume,source=vintage-story-data,target=/home/vintagestory/data \
  --mount type=volume,source=vintage-story-server,target=/home/vintagestory/server \
  --publish 42420:42420/tcp \
  --publish 42420:42420/udp \
  --env=GAME_VERSION='1.21.2' \
  --env=GAME_BRANCH='stable' \
  --env=serverName='My Really Cool Vintage Story Server' \
  --env=password='supersecretpasswordtojoinmycoolserver' \
  --env=graceTimer='3' \
  --env=caveIns='on' \
  --env=startupCommands="/op myplayername \n /moddb install playercorpse" \
  sknnr/vintage-story-server:latest
```
The above example is similar to the previous example, except we are not mounting a serverconfig.json file into the container. Instead, we are utilizing optional [Environment Variables](#environment-variables) to set the parameters we want to modify.

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
  vintage-story:
    image: sknnr/vintage-story-server:latest
    ports:
      - "42420:42420/tcp"
      - "42420:42420/udp"
    environment:
      - GAME_VERSION=1.21.2
    volumes:
      - vintage-story-data:/home/vintagestory/data
      - vintage-story-server:/home/vintagestory/server
volumes:
  vintage-story-data:
  vintage-story-server:
```

### Podman

To run the container in Podman, see the following examples.

#### Running with Podman and mounting a serverconfig.json file into the container
```bash
podman run \
  --detach \
  --name vintage-story \
  --mount type=volume,source=vintage-story-data,target=/home/vintagestory/data \
  --mount type=volume,source=vintage-story-server,target=/home/vintagestory/server \
  --mount type=bind,source=/my/local/path/to/serverconfig.json,target=/home/vintagestory/data/serverconfig.json \
  --publish 42420:42420/tcp \
  --publish 42420:42420/udp \
  --env=GAME_VERSION='1.21.2' \
  docker.io/sknnr/vintage-story-server:latest
```

#### Running with Podman and letting container build a serverconfig.json for you
```bash
podman run \
  --detach \
  --name vintage-story \
  --mount type=volume,source=vintage-story-data,target=/home/vintagestory/data \
  --mount type=volume,source=vintage-story-server,target=/home/vintagestory/server \
  --publish 42420:42420/tcp \
  --publish 42420:42420/udp \
  --env=GAME_VERSION='1.21.2' \
  --env=GAME_BRANCH='stable' \
  --env=serverName='My Really Cool Vintage Story Server' \
  --env=password='supersecretpasswordtojoinmycoolserver' \
  --env=graceTimer='3' \
  --env=caveIns='on' \
  --env=startupCommands="/op myplayername \n /moddb install playercorpse" \
  docker.io/sknnr/vintage-story-server:latest
```
The above example is similar to the previous example, except we are not mounting a serverconfig.json file into the container. Instead, we are utilizing optional [Environment Variables](#environment-variables) to set the parameters we want to modify.

### Quadlet
To run the container with Podman's new quadlet subsystem, make a file under (as root, or as user with sudo permission) /etc/containers/systemd/vintagestory.container containing:
```properties
[Unit]
Description=Vintage Story Game Server

[Container]
Image=docker.io/sknnr/vintage-story-server:latest
Volume=vintage-story-data:/home/vintagestory/data
Volume=vintage-story-server:/home/vintagestory/server
PublishPort=42420:42420/tcp
PublishPort=42420:42420/udp
ContainerName=vintage-story-server
Environment=GAME_VERSION="1.21.2"

[Service]
# Restart service when sleep finishes
Restart=always
# Extend Timeout to allow time to pull the image
TimeoutStartSec=900

[Install]
# Start by default on boot
WantedBy=multi-user.target default.target
```

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.
