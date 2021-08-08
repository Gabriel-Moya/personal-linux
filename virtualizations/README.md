# Solution found to start the virtual machines that I use together with the system when booting.

## Start VMs with the system
Insert the script responsible for starting the VMs in some directory, for example, we will use it directly in the home, insert the script responsible for starting the VMs in some directory, for example, we will use it directly in the home, so that the script is executed when starting the system, it is necessary to insert the code found in rc.local in ```/etc/ rc.local```.

## Stop VMs
To stop all machines from the command line, just locate the stop-vms-nogui.sh file and run it with sudo, as they were started in the boot process it will be running in the root session.
