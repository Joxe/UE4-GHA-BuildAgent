#!/bin/bash
# Runs the Runner!
# Example: Run-GitHubActionsRunner.sh --GitHubActionsInstallationFolder /home/user/actions-runner
#
# GitHubActionsInstallationFolder is the path to the run.sh script which is installed by configuring the GitHub Actions Runner.

GitHubActionsInstallationFolder=${GitHubActionsInstallationFolder:-""}

while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
	fi
	shift
done

if [[ -z "$GitHubActionsInstallationFolder" ]] || [[ ! -f "$GitHubActionsInstallationFolder/run.sh" ]]; then
	echo "Run script was not found!"
	echo "Looked for \"${GitHubActionsInstallationFolder}/run.sh\""
	exit 1
fi

${GitHubActionsInstallationFolder}/run.sh

exit 0