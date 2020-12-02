#!/bin/bash
# This script adds the GitHub Runner as a service so it's automatically run when the machine starts.
# Example: Register-AutoStartService.sh --User user
#
# User is the user that the service should run as. This should be the same as the user created when the VM is created.

User=${User:-""}

# Sets all the parameters to their respective value.
while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
	fi
	shift
done

if [ -z "${User}" ]; then
	echo "`basename $0`: No User specified with the --User flag!"
	exit 1
fi

echo "`basename $0`: Copying VagrantService.sh and VagrantGitHubRunner.service to the correct directories..."
cp /home/${User}/Linux/Runtime/Scripts/VagrantService.sh /usr/local/bin
cp /home/${User}/Linux/Runtime/Scripts/VagrantGitHubRunner.service /etc/systemd/system/

echo "`basename $0`: Modifying the user in VagrantGitHubRunner.service to be \"${User}\""
sed -i "s/User=not-set/User=${User}/g" /etc/systemd/system/VagrantGitHubRunner.service

echo "`basename $0`: Updating the permissions of the copied files, making VagrantService.sh executable."
chmod 640 /etc/systemd/system/VagrantGitHubRunner.service
chmod +x /usr/local/bin/VagrantService.sh

echo "`basename $0`: Adding the new service to the system..."
systemctl daemon-reload
systemctl enable VagrantGitHubRunner
echo "`basename $0`: VagrantGitHubRunner service added and enabled, let's check it's status..."
systemctl status VagrantGitHubRunner
echo "`basename $0`: VagrantGitHubRunner should be enabled and inactive."

echo "`basename $0`: Done!"
exit 0