#!/bin/bash
# Fetches the latest GitHub Actions Runner version number and outputs it into two files 'latest_version' and 'latest_runner_uri'
# The Public Access Token is optional but good to avoid being throttled to 60 requests per hour, using the PAT increases it to 5 000 per hour.
# Example: Get-GitHubActionsRunnerLatestVersionURI.sh --output /home/user/actions-runner --GitHubPAT <token>

output=${output:-"runner_download_uri.txt"}
GitHubPAT=${GitHubPAT:-""}

while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
	fi
	shift
done

if [ -n "${GitHubPAT}" ]; then
	GitHubApiHeaders="Authorization: token $GitHubPAT"
	LatestVersionLabel=$(curl https://api.github.com/repos/actions/runner/releases/latest -H "${GitHubApiHeaders}" | jq '.tag_name')
else
	LatestVersionLabel=$(curl https://api.github.com/repos/actions/runner/releases/latest | jq '.tag_name')
fi

LatestVersion=${LatestVersionLabel#"\""}
LatestVersion=${LatestVersion%"\""}
RunnerFileName="actions-runner-linux-x64-${LatestVersion#"v"}.tar.gz"
RunnerDownloadURI="https://github.com/actions/runner/releases/download/${LatestVersion}/${RunnerFileName}"

echo "`basename $0`: Saving files..."
echo ">${output}/latest_runner_uri"
echo ">${output}/latest_version"
echo "${RunnerDownloadURI}" > "${output}/latest_runner_uri"
echo "${LatestVersion}" > "${output}/latest_version"

# There's not much that can fail in this file, but check in case something did.
if [ $? -ne 0 ]; then
	echo "`basename $0`: Some error?"
	exit 1
fi

exit 0