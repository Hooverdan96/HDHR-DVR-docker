Originally forked from: https://github.com/demonrik/HDHR-DVR-docker

# HDHR-DVR-docker
Docker Wrapper for SiliconDust's HDHomeRun DVR Engine

Image based on latest Alpine Linux https://alpinelinux.org/

Contains a script to download the latest dvr engine after the container and before the engine is started. The engine resides within the container and not in a mounted folder.
To update the engine stop the container and restart, this will trigger the download of the latest version.
Pre-requisites are a valid DVR subscription and recent HDHomeRun Tuner hardware. More information can be found here: https://www.silicondust.com/dvr-service/

## DVR Engine User
The container is run as a root user (unless specified differently in docker run command), but the engine will be run with a different user.
So, for example, if the resulting files should be managed through a Plex server, then the user and group IDs of the HDHomeRun DVR need to be aligned with the user/user group of the Plex instance (or jellyfin, emby, kodi, etc.).
If the user/group on the host match this container's default, then none need to be passed.

| Environment Variable | Description |
|  --------| ------- |
| PGID | User Group ID (numeric value, not name), if not specified it will default to 1000 |
| PUID | User ID (numeric value, not name), if not specificied it will default to 1000 |

The values to be used can be determined in a variety of ways (search for "Linux find PGID, PUID").

## Volumes
| Volume | Description |
| --------| ------- |
| dvrrec | Recordings and the engine logs will be stored here |
| dvrdata | Temporary data such as the engine itself, the config file, and a log output of the containers script |

## Port Mapping
As the dvr engine resides inside the docker container, two ports need to be mapped.

| Destination Port | Description |
| --------| ------- |
| 65001 | udp port that is fixed, i.e. the mapping **always** has to be 65001:65001, this port is used by the HDHomeRun tuners and other clients to discover the dvr engine |
| 59090 | this tcp port can be mapped to from any port, e.g. 23000:59090 as this is used for the dvr engine's interaction with tuners/clients |

**Comment on using Host Network instead**

Based on latest testing, the container right now unfortunately still requires the ```net=host``` option.
Please consider security and other implications to your environment.
Trying to work out whether it will be possible without.
When using the ```net=host``` option, the explicit port mapping above is not really necessary (included in the below example nonetheless).

```
--network host
```

## HDHomeRun DVR Configuration file

the configuration file ```dvr.conf``` will be created during the first run of the container in the dvrdata volume. Subsequent stops/starts will inspect the file and recreate it if mapping/port are not aligned with what has been specified during the ```docker run``` command. There is an additional parameter added to the configuration file, that is used by this container. For adventurous users, there is the option to also include beta releases into the DVR engine updates.

| Parameter | Setting | Description |
| --------| ------- | ------- |
| BetaEngine | ```BetaEngine=0``` | Default Setting (created during initial launch of container. The script will compare the latest released engine (file creation date) with a possibly already installed engine and install the newer of the two. As long as the container is not restarted the engine won't be updated. |
| BetaEngine | ```BetaEngine=1``` | At the startup of the container the script evaluates the released, installed and beta engine versions (file creation date) and pick the newest one. As long as the container is not restarted the engine won't be updated. |

**Indirect assignment of target subfolder**

This is mostly relevant when this is used in a **NAS** type environment (e.g. [Rockstor](https://rockstor.com) where only Shares are assigned to the volume mapping.
If a subfolder of an existing share should be used to hold the TV recordings as well as the Live TV stream buffer (for pausing, etc.),
then the recording path in the ```dvr.conf``` (found in the folder that's assigned to the ```dvrdata``` volume) can be amended, with the subfolder (path).
However, the root of the path needs to remain intact to ensure that mapped volumes in the container continue to match.

Here is an example:

the volume DVR_Recordings is mapped to the dvrrec volume during the container creation/run (option ```-v /DVR_Recordings:/dvrrec```).
However, a subdirectory on the ```/DVR_Recordings``` volume named ```TV_Shows``` should be used, as the ```DVR_Recordings``` share is also used by another movie application (think Plex or Emby).
In order to have them separated, but on the same share, the host path ```/DVR_Recordings/TV_Shows``` needs to be reflected in the dvr.conf file:
after initial container creation/start, the ```dvr.conf``` file will have this line:

```RecordPath=/dvrrec``` - this would then be amended with

```RecordPath=/dvrrec/TV_Shows```

Save the ```dvr.conf``` file and restart the container. Ensure that ```dvrrec``` remains in that amended path at the beginning.

## Docker Run Example

Using Docker Hub container repository:

```
docker run -d --name hdhomerun_dvr \
  --restart=unless-stopped \
  --net=host \
  -p 65001:65001/udp \
  -p <any_tcp_port>:59090 \
  -e PGID = <numeric Group ID> \
  -e PUID = <numeric User ID> \
  -v /path/to/hdhomerun/config&startuplogs:/dvrdata \
  -v /path/to/hdhomerun/recordings&enginelogs:/dvrrec \
  jackdock96/hdh_dvr:latest
```

Using Github container respository:

```
docker run -d --name hdhomerun_dvr \
  --restart=unless-stopped \
  --net=host \
  -p 65001:65001/udp \
  -p <any_tcp_port>:59090 \
  -e PGID = <numeric Group ID> \
  -e PUID = <numeric User ID> \
  -v /path/to/hdhomerun/config&startuplogs:/dvrdata \
  -v /path/to/hdhomerun/recordings&enginelogs:/dvrrec \
  ghcr.io/hooverdan96/hdhr-dvr-docker:main
  ```
