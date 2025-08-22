#!/usr/bin/env sh
# shellcheck enable=all

# This function updates yo by downloading the latest version from the server and running the update script.
update_yo() {

	# If online, do things
	if system_is_online; then
		# Download the update script
		curl -s https://cmccomb.com/yo/install -o /tmp/yo_install.sh || {
			echo "Error: Failed to download the update script." >&2
			return 1
		}

		# Run the update script
		sh /tmp/yo_install.sh >/dev/null || {
			echo "Error: Failed to run the update script." >&2
			return 1
		}
	else
		echo "Error: You must be online to update yo." >&2
		return 1
	fi

}

# This function uninstalls yo by removing the binary and all associated files.
uninstall_yo() {

	# Remove you from /usr/local/bin
	sudo rm /usr/local/bin/yo || {
		echo "Error: Failed to remove /usr/local/bin/yo." >&2
		return 1
	}

	# Remove the side files from /usr/local/share/yo
	sudo rm -rf /usr/local/yo || {
		echo "Error: Failed to remove /usr/local/yo/." >&2
		return 1
	}
}
