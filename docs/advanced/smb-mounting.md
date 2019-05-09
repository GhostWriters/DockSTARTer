---
layout: default
---

# Linux Host
Create a file called `.credentials` or the like in your home folder. In this folder, you're going to put this:
```
username=<username to access resource>
password=<password to access resource>
```
substitute your own variables of course.

From here, you're going to want to install cifs-utils:
`sudo apt-get install cifs-utils`

Then once that's done, you should be able to mount your SMB/Windows Share like so:
```
sudo mount -t cifs //<host>/Downloads /mnt/downloads -o uid=1000,gid=1000,credentials=/home/<your home user>/.credentials,rw,vers=3.0
```
And to make sure that sticks, you're going to put this entry in your `/etc/fstab` file (You'll probably want to put it at the bottom) to match:
`//<host>/Downloads /mnt/downloads cifs uid=1000,gid=1000,credentials=/home/<your home user>/.mount-creds,rw,vers=3.0`

You should be able to reboot to test the mount, but you should now be able to `ls -al /mnt/Downloads` (in my example) and see the files in your Shared Downloads folder!

## OpLock issues
If you have containers that lock the drive and fail to unlock, you can deny the granting of opportunistic locks by setting the following registry entry:
```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\mrxsmb
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\mrxsmb20
EnableOplocks REG_DWORD 0
```

# Windows Host
`net use Z: \\host\Downloads`

### Related
#### Start a Samba server
See [[Samba]].
