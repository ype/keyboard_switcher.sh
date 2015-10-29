#!/bin/bash
## -*- Mode: Sh -*-                                                           ##
################################################################################
################################################################################
##                                                                            ##
## external keyboard check [ekc_check.sh]                                     ##
## Created: 29-10-2015                                                        ##
## Author: Anton Strilchuk <anton@env.sh>                                     ##
## URL: https://env.sh                                                        ##
## Version:                                                                   ##
## Last-Updated: 29-10-2015                                                   ##
##  Update #: 7                                                               ##
##   By: Anton Strilchuk <anton@env.sh>                                       ##
##                                                                            ##
## Description:                                                               ##
##   I have two keyboards, do you? Well TBH not exactly two keyboards but     ##
##   rather I have one internal keyboard on my laptop and little hhkb that    ##
##   I carry around with me wherever I may go. Up until recently I have       ##
##   manual switched between the internal and external keyboard configs       ##
##   everytime I decide I want to use my external while on my laptop, also    ##
##   the hhkb is small enough to cover the keys on a macbook 15" as if it     ##
##   was design to do so. The issue I had was that when I placed my hhkb on   ##
##   the keyboard in my macbook I had the issue of keys being triggered at    ##
##   random intervals depending on how hard I was typing. Now disabling the   ##
##   internal keyboard manual is an option, but unfortunately I ran into a    ##
##   snag everytime I forgot my internal keyboard was disabled and decided    ##
##   to switch back to it after using my external. To solve my headache and   ##
##   subsequent butt hurt - I wrote this little script, which checks to see   ##
##   if my external keyboard is plugged in, if it's not, then the internal    ##
##   keyboard gets enabled and keybindings set, if the external is connected  ##
##   then the internal keyboard gets disabled, and different hhkb specific    ##
##   keybindings get set.                                                     ##
##                                                                            ##
##   Command line tools I used:                                               ##
##     xinput: http://sourceforge.net/projects/xinput/                        ##
##     lsusb:  http://mj.ucw.cz/sw/pciutils/                                  ##
##     xkb:    (optional)                                                     ##
##     xcape:  (optional)                                                     ##
##                                                                            ##
################################################################################
################################################################################
##
## Code:

# DEBUG using: -d
[[ "$@" == "-d" ]] && set -x

INTERNAL_KEYBOARD_NAME='Apple' # Find this using xinputs
EXTERNAL_KEYBOARD_NAME='HHKB'  # Find this using lsusb
# NOTE: to find the name of your keyboards use the xinput command to find it from your systems list available input devices

# Get the ID of the internal keyboard from xinputs list on devices
internal_kbd_id=$(xinput | grep $INTERNAL_KEYBOARD_NAME | cut -d'=' -f2 | grep -Eo '[0-9]+')

enable_external() {
    _internal_enabled=0 # INTERNAL KEYBOARD STATE: OFF

    # float (detach) internal keyboard
    xinput float 10

    # xkb keymap for external keyboard using xkbcomp
    xkbcomp -w 0 $HOME/xkb/hhkb_custom.xkb $DISPLAY;
    $HOME/.i3/scripts/xcape_keys.sh # some nifty key functions using xcape
    _external_enabled=1 # EXTERNAL KEYBOARD STATE: ON
}

enable_internal() {
    _external_enabled=0 # EXTERNAL KEYBOARD STATE: OFF

    # reattach internal keyboard
    xinput reattach 10 3;

    # xkb keymap for internal keyboard using xkbcomp
    xkbcomp -w 0 $HOME/xkb/xkb_internal.xkb $DISPLAY;

    # some nifty key functions using xcape
    $HOME/.i3/scripts/xcape_keys.sh;

    _internal_enabled=1 # INTERNAL KEYBOARD STATE: ON
}

check_keys_state() {
    # make shit float
    # see also: detaching internal keyboard using xinput
    [[ ! -z $(xinput | grep -E "$INTERNAL_KEYBOARD_NAME" | grep -Eo 'floating') ]] && _ekc_floating=1 || _ekc_floating=0

    # find stuff
    # see also: using lsusb to stat attach usb devices
    [[ ! -z $(lsusb | grep -Eo "$EXTERNAL_KEYBOARD_NAME") ]] \
        && _ekc_hhkb=1 || _ekc_hhkb=0
}

main() {
    check_keys_state

    [[ $_ekc_hhkb == 0 ]] \
        && [[ $_internal_enabled == 0 ]] \
        && enable_internal && echo "$(date): internal"

    [[ $_ekc_hhkb == 0 ]] \
        && [[ $_ekc_floating == 1 ]] \
        && enable_internal && echo "$(date): internal"

    [[ $_ekc_hhkb == 1 ]] \
        && [[ $_external_enabled == 0 ]] \
        && [[ $_ekc_floating == 0 ]] \
        && enable_external && echo "$(date): external"
}

# RUN MAIN
while true; do
    main
    sleep 3
done

################################################################################
#### ekc_check.sh ends here
