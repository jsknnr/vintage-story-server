#!/bin/bash
# This script dynamically builds a serverconfig.json from exmaple_serverconfig.json and sets attributes
# based on supplied serverconfig environment variables

# Declare list of serverconfig env vars and their respective paths in serverconfig.json
declare -A var_paths=(
  ["serverName"]="ServerName"
  ["serverDescription"]="ServerDescription"
  ["welcomeMessage"]="WelcomeMessage"
  ["advertiseServer"]="AdvertiseServer"
  ["port"]="Port"
  ["maxPlayers"]="MaxClients"
  ["password"]="Password"
  ["mapSizeX"]="MapSizeX"
  ["mapSizeZ"]="MapSizeZ"
  ["mapSizeY"]="MapSizeY"
  ["mapSizeY"]="WorldConfig.MapSizeY"
  ["serverLanguage"]="ServerLanguage"
  ["seed"]="WorldConfig.Seed"
  ["worldName"]="WorldConfig.WorldName"
  ["allowCreative"]="WorldConfig.AllowCreativeMode"
  ["playStyle"]="WorldConfig.PlayStyle"
  ["playStyleLangCode"]="WorldConfig.PlayStyleLangCode"
  ["gameMode"]="WorldConfig.WorldConfiguration.gameMode"
  ["startingClimate"]="WorldConfig.WorldConfiguration.startingClimate"
  ["spawnRadius"]="WorldConfig.WorldConfiguration.spawnRadius"
  ["graceTimer"]="WorldConfig.WorldConfiguration.graceTimer"
  ["deathPunishment"]="WorldConfig.WorldConfiguration.deathPunishment"
  ["droppedItemsTimer"]="WorldConfig.WorldConfiguration.droppedItemsTimer"
  ["seasons"]="WorldConfig.WorldConfiguration.seasons"
  ["playerLives"]="WorldConfig.WorldConfiguration.playerLives"
  ["lungCapacity"]="WorldConfig.WorldConfiguration.lungCapacity"
  ["daysPerMonth"]="WorldConfig.WorldConfiguration.daysPerMonth"
  ["harshWinters"]="WorldConfig.WorldConfiguration.harshWinters"
  ["blockGravity"]="WorldConfig.WorldConfiguration.blockGravity"
  ["caveIns"]="WorldConfig.WorldConfiguration.caveIns"
  ["allowUndergroundFarming"]="WorldConfig.WorldConfiguration.allowUndergroundFarming"
  ["bodyTemperatureResistance"]="WorldConfig.WorldConfiguration.bodyTemperatureResistance"
  ["creatureHostility"]="WorldConfig.WorldConfiguration.creatureHostility"
  ["creatureStrength"]="WorldConfig.WorldConfiguration.creatureStrength"
  ["playerHealthPoints"]="WorldConfig.WorldConfiguration.playerHealthPoints"
  ["playerHungerSpeed"]="WorldConfig.WorldConfiguration.playerHungerSpeed"
  ["playerHealthRegenSpeed"]="WorldConfig.WorldConfiguration.playerHealthRegenSpeed"
  ["playerMoveSpeed"]="WorldConfig.WorldConfiguration.playerMoveSpeed"
  ["foodSpoilSpeed"]="WorldConfig.WorldConfiguration.foodSpoilSpeed"
  ["saplingGrowthRate"]="WorldConfig.WorldConfiguration.saplingGrowthRate"
  ["toolDurability"]="WorldConfig.WorldConfiguration.toolDurability"
  ["toolMiningSpeed"]="WorldConfig.WorldConfiguration.toolMiningSpeed"
  ["propickNodeSearchRadius"]="WorldConfig.WorldConfiguration.propickNodeSearchRadius"
  ["globalDepositSpawnRate"]="WorldConfig.WorldConfiguration.globalDepositSpawnRate"
  ["microblockChiseling"]="WorldConfig.WorldConfiguration.microblockChiseling"
  ["allowCoordinatedHud"]="WorldConfig.WorldConfiguration.allowCoordinatedHud"
  ["allowMap"]="WorldConfig.WorldConfiguration.allowMap"
  ["colorAccurateWorldmap"]="WorldConfig.WorldConfiguration.colorAccurateWorldmap"
  ["loreContent"]="WorldConfig.WorldConfiguration.loreContent"
  ["clutterObtainable"]="WorldConfig.WorldConfiguration.clutterObtainable"
  ["temporalStorms"]="WorldConfig.WorldConfiguration.temporalStorms"
  ["temporalstormDurationMul"]="WorldConfig.WorldConfiguration.temporalstormDurationMul"
  ["temporalStability"]="WorldConfig.WorldConfiguration.temporalStability"
  ["temporalRifts"]="WorldConfig.WorldConfiguration.temporalRifts"
  ["temporalGearRespawnUses"]="WorldConfig.WorldConfiguration.temporalGearRespawnUses"
  ["temporalStormSleeping"]="WorldConfig.WorldConfiguration.temporalStormSleeping"
  ["worldClimate"]="WorldConfig.WorldConfiguration.worldClimate"
  ["landcover"]="WorldConfig.WorldConfiguration.landcover"
  ["oceanscale"]="WorldConfig.WorldConfiguration.oceanscale"
  ["upheavelCommonness"]="WorldConfig.WorldConfiguration.upheavelCommonness"
  ["geologicActivity"]="WorldConfig.WorldConfiguration.geologicActivity"
  ["landformScale"]="WorldConfig.WorldConfiguration.landformScale"
  ["worldEdge"]="WorldConfig.WorldConfiguration.worldEdge"
  ["polarEquatorDistance"]="WorldConfig.WorldConfiguration.polarEquatorDistance"
  ["globalTemperature"]="WorldConfig.WorldConfiguration.globalTemperature"
  ["globalPercipitation"]="WorldConfig.WorldConfiguration.globalPercipitation"
  ["globalForestation"]="WorldConfig.WorldConfiguration.globalForestation"
  ["surfaceCopperDeposits"]="WorldConfig.WorldConfiguration.surfaceCopperDeposits"
  ["surfaceTinDeposits"]="WorldConfig.WorldConfiguration.surfaceTinDeposits"
  ["snowAccum"]="WorldConfig.WorldConfiguration.snowAccum"
  ["allowLandClaiming"]="WorldConfig.WorldConfiguration.allowLandClaiming"
  ["classExclusiveRecipes"]="WorldConfig.WorldConfiguration.classExclusiveRecipes"
  ["auctionHouse"]="WorldConfig.WorldConfiguration.auctionHouse"
  ["onlyWhitelisted"]="OnlyWhitelisted"
  ["allowPvP"]="AllowPvP"
  ["allowFireSpread"]="AllowFireSpread"
  ["allowFallingBlocks"]="AllowFallingBlocks"
  ["startupCommands"]="StartupCommands"
)

# Prepare jq command with dynamically added arguments
jq_command="jq '"
jq_args=""

for var in "${!var_paths[@]}"
do
  if [ -n "${!var}" ]; then
    jq_path="${var_paths[$var]}"
    jq_command="$jq_command .$jq_path = \$$var |"
    jq_args="$jq_args --arg $var $'${!var}'"
  fi
done

# Set paths and remove the trailing '|' from the jq command
jq_command="${jq_command% |}' ${VINTAGE_STORY_PATH}/example_serverconfig.json > ${VINTAGE_STORY_PATH}/data/serverconfig.json"

# Combine jq command and arguments
final_command="$jq_command $jq_args"

# Run the jq command
eval $final_command
