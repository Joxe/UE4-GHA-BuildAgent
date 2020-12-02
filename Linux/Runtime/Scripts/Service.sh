#!/bin/bash
# This script is called by the VagrantGitHubRunner/GoogleCloud service and works as an entry point to start the automatic update
# and then run the GitHub Actions Runner. This is the script that receives the data required to connect to GitHub and whatnot.
# Example: Service.sh --User user --GitHubActionsInstallationFolder /home/user/actions-runner --GitHubPAT <some hash> --GitHubScope UrlToGitRepo --AgentName Name
#
# User is so we can find the correct directory under /home for the scripts that we need to run. It might be possible to substitute this with the 'whoami' command.
# GitHubActionsInstallationFolder is where to install the GitHub Runner files.
# GitHubPAT is the access token to be able to connect to GitHub as a user.
# GitHubScope is the subdirectory for the repository in the URL. If your repo is located at https://github.com/User/MyRepo then the GitHubScope would be User/MyRepo.
# GitHubHostName ??? I just found this one in the Windows version.
# AgentName The name and one of the labels for the Agent that will be built.

User=${User:-""}
GitHubActionsInstallationFolder=${GitHubActionsInstallationFolder:-""}
GitHubPAT=${GitHubPAT:-""}
GitHubScope=${GitHubScope:-""}
GitHubHostName=${GitHubHostName:-""}
AgentName=${AgentName:-""}

while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
	fi
	shift
done

if [ -z $GitHubActionsInstallationFolder ]; then
	echo "`basename $0`: --GitHubActionsInstallationFolder parameter was not set!"
	exit 1
fi

if [ -z $GitHubPAT ]; then
	echo "`basename $0`: --GitHubPAT parameter was not set!"
	exit 1
fi

if [ -z $GitHubScope ]; then
	echo "`basename $0`: --GitHubScope parameter was not set!"
	exit 1
fi

if [ -z $User ]; then
	echo "`basename $0`: --User was not set!"
	exit 1
fi

Arguments=("--GitHubActionsInstallationFolder" "${GitHubActionsInstallationFolder}" "--GitHubPAT" "${GitHubPAT}" "--GitHubScope" "${GitHubScope}")

# Add GitHubHostName to the list of arguments if it's set
if [ -n $GitHubHostName ]; then
	Arguments+=("--GitHubHostName")
	Arguments+=("${GitHubHostName}")
fi

# Add AgentName to the list of arguments if it's set, otherwise the GitHub config will randomize some name for us.
if [ -n $AgentName ]; then
	Arguments+=("--AgentName")
	Arguments+=("${AgentName}")
fi

echo "`basename $0`: Downloading the latest GitHub Actions Runner (if necessary)..."
/home/${User}/Linux/Runtime/Tools/Scripts/Get-LatestRunnerVersion.sh --InstallPath ${GitHubActionsInstallationFolder} --ScriptRoot "/home/${User}/Linux" --GitHubPAT ${GitHubPAT}

if [ $? -ne 0 ]; then
	echo "`basename $0`: FAILED downloading the latest GitHub Actions Runner!"
	exit 1
fi

echo "`basename $0`: Configuring GitHub Actions Runner..."
/home/${User}/Linux/Runtime/Tools/Scripts/Configure-GitHubActionsRunner.sh "${Arguments[@]}"

if [ $? -ne 0 ]; then
	echo "`basename $0`: FAILED runner configuration!"
	exit 1
fi

echo "`basename $0`: Launching GitHub Actions Runner..."
/home/${User}/Linux/Runtime/Tools/Scripts/Run-GitHubActionsRunner.sh --GitHubActionsInstallationFolder ${GitHubActionsInstallationFolder}

if [ $? -ne 0 ]; then
	echo "`basename $0`: FAILED to launch the runner!!"
	exit 1
fi

echo "`basename $0`: Done."
exit 0