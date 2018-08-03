#!/usr/bin/env bash
#set -o errexit; set -o errtrace; set -o pipefail # Exit on errors
# Uncomment line below for debugging:
#PS4=$'+ $(tput sgr0)$(tput setaf 4)DEBUG ${FUNCNAME[0]:+${FUNCNAME[0]}}$(tput bold)[$(tput setaf 6)${LINENO}$(tput setaf 4)]: $(tput sgr0)'; set -o xtrace
__deps=( "sed" "grep" "bc" )
for dep in ${__deps[@]}; do hash $dep >& /dev/null || (echo "$dep was not found. Please install it and try again." && exit 1); done


# Calculates for how long we should run the auto renamer
echo "Run for how long? [10 minutes]"
read timeToRename
timePassedUntilNow=0
timeStartedRenaming=$(date +%s)
timeToRename=$(( $(date +%s -d "+ $timeToRename") - $timeStartedRenaming ))
if [[ ! $timeToRename -ge 0 ]]; then
    echo "Error! Please input date in valid format, see examples:"
    echo "+16 minutes"
    echo "+2hours"
    exit
else
    echo "Running for a total of ${timeToRename} seconds..."
fi

$totalPokemonRenamed=0

# Original device width and height
W=1080
H=1920

# Replay device width and height (if same nothing changes)
#dWidth=1080
#dHeight=1920
dWidth=$(adb shell wm size | sed 's/..* \([0-9][0-9]*\)x..*/\1/')
dHeight=$(adb shell wm size | sed 's/..* [0-9][0-9]*x\([0-9][0-9]*\)$/\1/')

#echo "Starting clipper..."
#adb shell "am startservice ca.zgrs.clipper/.ClipboardService"
echo "Clearing clipboard..."
adb shell 'am broadcast -a clipper.set -e text ""' &>/dev/null


function click {
    if [[ $# -lt 2 ]]; then
        echo "Must supply at least 2 arguments to click(): x y [description]"
        exit
    fi

    xx=$(echo "scale=10; x = $1 / $W; x*$dWidth " | bc | awk '{printf("%d\n",$1 + 0.5)}')
    yy=$(echo "scale=10; y = $2 / $H; y*$dHeight" | bc | awk '{printf("%d\n",$1 + 0.5)}')

    #echo "shell input tap $xx $yy"

    adb shell input tap $xx $yy

    [[ ! -z $3 ]] && echo $3 || true
}


for (( t = 0; t <= timeToRename; t++ )); do
    timePerRound=$(date +%s)
    click 752 1307 'Tap blank spot'

    click 157 1730 'Tap IV button and wait'
    sleep 1

    click 909 1730 'Tap menu'
    click 752 1307 'Tap appraise and wait'
    sleep 1
    click 752 1307 'Tap and wait a looot'
    sleep 5

    click 752 1307 'Tap and wait'
    sleep 0.75

    click 752 1307 'Tap and wait'
    sleep 0.75

    click 752 1307 'Tap and wait'
    sleep 0.75

    click 752 1307 'Tap and wait'
    sleep 0.75

    click 100 1300 'Tap'

    click 100 1300 'Tap'

    click 100 1300 'Tap'


    click 770 650 'Tap Check IV'

    pokemon=$(adb shell am broadcast -a clipper.get)
    pokemon=$(echo ${pokemon} | sed 's/.*data\=\"\(..*\)".*/\1/')

    isBadClipboard=$(echo $pokemon | egrep 'PokemonId|Broadcasting|Intent' -c)

    if [ "$lastPokemon" == "$pokemon" ]; then
        isSameAsLastOne=1
    else
        isSameAsLastOne=0
    fi

    click 1000 1320 'Tap close button'


    if [[ $isBadClipboard -ge "1" || $isSameAsLastOne -ge "1" ]]; then
        echo "something happened, pokemon is $pokemon, lastPokemon is $lastPokemon"
        echo isBadClipboard$isBadClipboard
        echo isSameAsLastOne$isSameAsLastOne
        echo "bye bye!"
        skipRename=1
    else
        echo "renaming pokemon $pokemon. wait..."
        sleep 0.75
        skipRename=0
    fi

    lastPokemon="$pokemon"

    if [ "$skipRename" != "1" ]; then
        click 540 880 'Tap name'

        adb shell input keyevent KEYCODE_PASTE
        adb shell input keyevent TAB
        adb shell input keyevent KEYCODE_ENTER
        click 520 1030 'clicking ok on pokemon'

    fi

    echo 'moving on...'
    sleep 1.2
    adb shell input swipe 900 1140 160 1140 500

    timePerRound=$(( $(date +%s) - $timePerRound ))
    t=$((timePerRound+t))
    let totalPokemonRenamed++
    echo -e "The round took $(( $timePerRound )) seconds. Total time so far is $t. Total Pokémon renamed: $totalPokemonRenamed\n====================================\n"
done
