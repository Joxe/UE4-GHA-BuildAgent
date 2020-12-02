#!/bin/bash
# This script is making sure that you have the latest GitHub Actions Runner version installed.
# Example: Get-LatestRunnerVersion.sh --InstallPath /home/user/actions-runner --ScriptRoot /home/user/Linux --GitHubPAT <hashed string>
#
# InstallPath is where the Runner should be installed to, the system can run this as root if necessary but I use the home directory to avoid running things as root.
# ScriptRoot is the path to the Linux/ directory containing all the scripts that is copied over to the VM when it's created.
# GitHubPAT is the access token to a GitHub account, it's not required for this script to complete but without it all requests to the GitHub API is throtted to 60 per hour while an authenticated user gets 5 000 per hour.

InstallPath=${InstallPath:-""}
ScriptRoot=${ScriptRoot:-""}
GitHubPAT=${GitHubPAT:-""}

# Sets all the parameters to their respective value.
while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
	fi
	shift
done

if [ -z "${InstallPath}" ]; then
	echo "`basename $0`: --InstallPath was not set!"
	exit 1
fi

# Make sure that the install path exists
if [ ! -d "${InstallPath}" ]; then
	mkdir ${InstallPath}

	if [ $? -ne 0 ]; then
		echo "`basename $0`: Unable to create directory at ${InstallPath}, make sure you have the correct permissions!"
		exit 1
	fi
fi

# Change working directory to the install path
cd ${InstallPath}

# Get the current version of the runner on the server, saves the output to the files 'latest_version' and 'latest_runner_uri'
${ScriptRoot}/ImageCreation/Tools/Scripts/Get-GitHubActionsRunnerLatestVersionURI.sh --output "${InstallPath}" --GitHubPAT "${GitHubPAT}"
InstalledVersion="None"

# Read the latest version number from the 'latest_version' file, should read something like 'v2.32.5'
if [ -f "latest_version" ]; then
	LatestVersion=$(< latest_version)

	# Read the URI to the latest version of the runner.
	if [ -f "latest_runner_uri" ]; then
		LatestVersionURI=$(< latest_runner_uri)
	else
		echo "`basename $0`: Was able to find latest version but not the latest version URI!"
		exit 1
	fi
else
	echo "`basename $0`: Could not retrieve latest version!"
	exit 1
fi

# Check if we have an installed version of the runner already, this is currently being done as a text file but could probably be changed to a
# command that asks the actual installed runner for the version number.
if [ -f "installed_version" ]; then
	echo "`basename $0`: Found installed version at \"installed_version\"!"
	InstalledVersion=$(< installed_version)
	echo "`basename $0`: Installed Version: ${InstalledVersion}"
else
	echo "`basename $0`: No installed version!"
fi

echo "`basename $0`: Latest Version: ${LatestVersion}"

# Just do a string-check to see if the latest version differs from the installed version.
if [ "${InstalledVersion}" == "${LatestVersion}" ]; then
	echo "`basename $0`: Latest version is already installed (${LatestVersion})"

	# Clean up the temporary files.
	rm "latest_runner_uri"
	rm "latest_version"

	# We are now up to date!
	exit 0
else
	echo "`basename $0`: Downloading and un-taring the latest version (${LatestVersion}) to file \"linux64runner.tar.gz\"..."

	# Download the latest version. We rename it to have an easier time referring the file.
	curl -L ${LatestVersionURI} -o linux64runner.tar.gz

	# Unpack the tarball, the runner does not need to be installed, an unpacked tar is considered installed.
	tar xzf "linux64runner.tar.gz"

	if [ $? -ne 0 ]; then
		echo "`basename $0`: Download failed!"
		exit 1
	fi

	# Remove the previous installed_version file.
	if [ -f "installed_version" ]; then
		rm "installed_version"
	fi

	# Rename the 'latest_version' to 'installed_version'
	mv "latest_version" "installed_version"

	echo "`basename $0`: Removing generated and downloaded files so you do not accidentally reuse them."
	rm "latest_runner_uri" "linux64runner.tar.gz"
	exit 0
fi