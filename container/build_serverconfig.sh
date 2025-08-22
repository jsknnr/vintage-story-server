#!/usr/bin/env bash
set -euo pipefail

# 1. Paths to example and output JSON
BASE="${VINTAGE_STORY_PATH}"
INPUT="$BASE/example_serverconfig.json"
OUTPUT="$BASE/data/serverconfig.json"

# 2. Map of env-var names → JSON paths
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

# 3. Build jq arguments and the update filter
declare -a jq_args=()
filter=""

for var in "${!var_paths[@]}"; do
  val="${!var:-}"  
  [[ -z "$val" ]] && continue

  # Detect integers or scientific floats
  if [[ "$val" =~ ^-?[0-9]+([eE][+-]?[0-9]+)?$ ]]; then
    # Print as a plain integer (no exponent)
    normalized=$(printf "%.0f" "$val")
    jq_args+=( "--argjson" "$var" "$normalized" )
  elif [[ "$val" == "true" || "$val" == "false" ]]; then
    jq_args+=( "--argjson" "$var" "$val" )
  else
    jq_args+=( "--arg" "$var" "$val" )
  fi

  # Build the filter
  [[ -z "$filter" ]] && filter=".${var_paths[$var]} = \$$var" \
    || filter="$filter | .${var_paths[$var]} = \$$var"
done

# 4. Run jq in one shot
#    - ${jq_args[@]} injects all --arg/--argjson pairs
#    - "$filter" is the combined update expression
jq "${jq_args[@]}" "$filter" "$INPUT" > "$OUTPUT"
