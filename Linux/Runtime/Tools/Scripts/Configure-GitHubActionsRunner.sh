#!/bin/bash
# Runs GitHub Actions runner configuration script, if the runner isn't already configured.
# Example: Configure-GitHubActionsRunner.sh --GitHubActionsInstallationFolder /home/user/actions-runner --GitHubPAT <token> --GitHubScope User/Repo --AgentName MySecretAgent
#
# GitHubActionsInstallationFolder is where your runner is installed by the Get-LatestRunnerVersion.sh script.
# GitHubPAT is the Public Access Token to the GitHub account, used to authoritize with GitHub
# GitHubScope is the user and repo combination, if your repository is located at https://github.com/User/Repo then this should be User/Repo
# AgentName is the name and one of the labels of the runner

GitHubActionsInstallationFolder=${GitHubActionsInstallationFolder:-""}
GitHubPAT=${GitHubPAT:-""}
GitHubScope=${GitHubScope:-""}
AgentName=${AgentName:-""}
GitHubHostname=${GitHubHostname:-""}

while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
	fi
	shift
done

if [ -z "$GitHubActionsInstallationFolder" ]; then
	echo "`basename $0`: Parameter 'GitHubActionsInstallationFolder' was not set! Please set it with --GitHubActionsInstallationFolder <value>."
	exit 1
fi

if [ -z "$GitHubPAT" ]; then
	echo "`basename $0`: Parameter 'GitHubPAT' was not set! Please set it with --GitHubPAT <value>."
	exit 1
fi

if [ -z "$GitHubScope" ]; then
	echo "`basename $0`: Parameter 'GitHubScope' was not set! Please set it with --GitHubScope <value>."
	exit 1
else
	if [[ "$GitHubScope" =~ "/" ]]; then
		OrgsOrRepos="repos"
	else
		OrgsOrRepos="orgs"
	fi
fi

if [ -z "$AgentName" ]; then
	echo "`basename $0`: Parameter 'AgentName' was not set! Please set it with --AgentName <value>."
	exit 1
fi

if [ -n "$GitHubHostname" ]; then
	GitHubApiUrl="https://${GitHubHostname}/api/v3" 
else
	GitHubApiUrl="https://api.github.com"
fi

# This should be the only header that is required, but my knowledge of HTTP stuff is low so there's a chance I've missed something.
GitHubApiHeaders="Authorization: token $GitHubPAT"
GetRunnersURI="${GitHubApiUrl}/${OrgsOrRepos}/${GitHubScope}/actions/runners"

# Look for existing runners on the GitHub repository and store their names.
RunnerAgentNames=()
for runner in $(curl -X GET -H "$GitHubApiHeaders" "$GetRunnersURI" | jq '.runners[].name'); do
	RunnerAgentNames+=$runner
done

RunnerConfigFile="$GitHubActionsInstallationFolder/.runner"

# Check if we're registering a new completely new runner
if [[ ${#RunnerAgentNames[@]} -eq 0 ]] || [[ !"$RunnerAgentNames" =~ "$AgentName" ]]; then
	# Remove the previous configuration files for this machine if it exists.
	if [ -f $RunnerConfigFile ]; then
		echo "`basename $0`: Runner is not registered with the GHA backend; removing local configuration"
		rm "$RunnerConfigFile"
		rm "$GitHubActionsInstallationFolder/.credentials_rsaparams"
		rm "$GitHubActionsInstallationFolder/.credentials"
	fi
fi

# If the configuration file doesn't exist it means that this runner is not configured, so we need to call 'config.sh'
if [ ! -f "$RunnerConfigFile" ]; then
	echo "`basename $0`: Runner is not configured; running configuration script"
	GetTokenURI="${GitHubApiUrl}/${OrgsOrRepos}/${GitHubScope}/actions/runners/registration-token"

	# Retrieve a token for registering a runner from GitHub, can only be done if you have the authentication for an account.
	# Do not save this value on disk, while it's only usable once and refreshes every hour it could potentially be a security issue.
	Token=$(curl -X POST -H "$GitHubApiHeaders" "$GetTokenURI" | jq -r '.token')
	
	if [ -n "$GitHubHostname" ]; then
		RegistrationURI="https://${GitHubHostname}/${GitHubScope}"
	else
		RegistrationURI="https://github.com/${GitHubScope}"
	fi

	# Call the GitHub Runner configuration script, this one is supplied from GitHub so if they change something we need to reflect those changes here.
	${GitHubActionsInstallationFolder}/config.sh --unattended --replace --url ${RegistrationURI} --token ${Token} --name ${AgentName} --labels ${AgentName}

	# Double check if everything was fine, hopefully we will have an output if it wasn't.
	if [ $? -ne 0 ]; then
		echo "`basename $0`: Config failed"
		exit 1
	fi
fi

exit 0