#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#colors for terminal
bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

# if [ -f /etc/profile.d/deploy_server.sh ]; then
# 	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
# 	export PATH=$PATH:$path
# fi

########################################################################################
#                                                                                      #
# Function to Print a Banner                                                           #
# Arguments:                                                                           #
#   $1 - Title of the banner                                                           #
#   $2 - Message to display                                                            #
#   $3 - Type of message (error, success, warning, info)                               #
#   $4 - Secondary message (optional)                                                  #
# Returns:                                                                             #
#   None                                                                               #
########################################################################################
# Example usage:		                                                                   #
#   print_banner "Title" "This is a message" "info" "Secondary message"                #
#   print_banner "Title" "This is a message" "error"                                   #
#   print_banner "Title" "This is a message" "success" "Secondary message"             #
#                                                                                      #
########################################################################################

function print_banner() {
	local title="$1"
	local message="$2"

	local length=${#message}
	if ((length % 2 == 0)); then
		message="$message "
	else
		message="$message"
	fi

	length=${#title}
	if ((length % 2 == 0)); then
		title="$title "
	else
		title="$title"
	fi

	local type="${3:-info}"
	local secondary_message="${4:-''}"

	length=${#secondary_message}
	if ((length % 2 == 0)); then
		secondary_message="$secondary_message "
	else
		secondary_message="$secondary_message"
	fi

	local bold_red="\e[1;31m"
	local cyan="\e[1;36m"
	local green="\e[1;32m"
	local reset="\e[0m"
	local yellow="\e[0;33m"

	local color
	case "$type" in
	error)
		color="$bold_red"
		;;
	success)
		color="$green"
		;;
	warning)
		color="$yellow"
		;;
	info)
		color="$cyan"
		;;
	*)
		color="$cyan"
		;;
	esac

	local width=80
	local padding_title=$(((width - ${#title}) / 2))
	local padding_message=$(((width - ${#message}) / 2))
	local padding_secondary_message=$(((width - ${#secondary_message}) / 2))

	local centered_title
	local centered_message
	centered_title=$(printf "%*s%s%*s" $padding_title "" "$title" $padding_title "")
	centered_message=$(printf "%*s%s%*s" $padding_message "" "$message" $padding_message "")

	echo ""
	echo "#################################################################################"
	echo "#                                                                               #"
	echo -e "#${color}${centered_title}${reset}#"
	echo "#                                                                               #"
	echo -e "#${color}${centered_message}${reset}#"
	echo "#                                                                               #"
	if [ ${#secondary_message} -gt 3 ]; then
		local centered_secondary_message
		centered_secondary_message=$(printf "%*s%s%*s" $padding_secondary_message "" "$secondary_message" $padding_secondary_message "")
		echo -e "#${color}${centered_secondary_message}${reset}#"
		echo "#                                                                               #"
	fi
	echo "#################################################################################"
	echo ""
}
