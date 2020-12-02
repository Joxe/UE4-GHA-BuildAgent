#!/bin/bash
# This is the Vagrant Specific file that contains all the data necessary to get a GitHub Actions Runner working on a local build of Ubuntu.
# It should reside in the /usr/local/bin/ directory and be called by the installed service in Ubuntu (see Register-AutoStartService.sh for more info on that)
# To make it work you have to fill it out with data that matches your GitHub account.

# LinuxUser is the user which is going to be used by the service, this should be the exact same user as the one created when creating the VM.
LinuxUser=""

# The installation directory for the actions runner. Make sure this is a directory owned by LinuxUser.
GitHubActionsInstallationFolder="/home/${LinuxUser}/actions-runner"

# The Public Access Token that you create for your account at GitHub.
GitHubPAT=""

# The subdomain for the GitHub repository, if your repository is located at https://github.com/User/Repository then you set this variable to 'User/Repository'
GitHubScope=""

# No clue, copied from the Windows scripts.
GitHubHostName=""

# The name and one of the labels to give the Agent when it's registered at GitHub.
AgentName=""

echo "`basename $0`: Launching Service script..."

ServiceParams=("--GitHubActionsInstallationFolder" "${GitHubActionsInstallationFolder}" "--GitHubPAT" "${GitHubPAT}" "--GitHubScope" "${GitHubScope}" "--User" "${LinuxUser}")

if [ -n "${GitHubHostName}" ]; then
	ServiceParams+=("--GitHubHostName")
	ServiceParams+=(${GitHubHostName})
fi

if [ -n "${AgentName}" ]; then
	ServiceParams+=("--AgentName")
	ServiceParams+=(${AgentName})
fi

/home/${LinuxUser}/Linux/Runtime/Scripts/Service.sh ${ServiceParams[@]}

if [ $? -eq 0 ]; then
	echo "`basename $0`: Done."
	exit 0
else
	echo "`basename $0`: Exited, but with errors!"
	exit 1
fi
