# Dockerfile for HDHomeRun DVR
# The initial container will create a base Alpine Linux image and install
# runtime script which will download the latest record engine, configure it
# if no config already exists and then start the engine.
# To update the record engine, simply stop the container, and restart

# FROM alpine: 3.20.2 (as of 08/19/2024)
# changed to latest tag for periodic automatic updates
FROM alpine:latest AS builder

##########################################################################
# Base Variables
# Default Directories
# ARG wrkdir HDHomeRunDVR
# ARG dvrdata dvrdata
# ARG dvrrec dvrrec
# User/User Group
# ENV user=hdhr
# ENV group=hdhr
# Default PGID/PUID
# ENV uid=1000
# ENV gid=1000
# Default Ports
# https://info.hdhomerun.com/info/dvr:troubleshooting#firewall
# 65001/udp required for HDHomeRun discovery and for clients to discover the record engine
# ENV udp_port=65001
# anyport/tcp for client interaction with dvr
# If changing, requires hdhomerun.sh adjustment (to update config file) as well
# ENV tcp_port=59090

##########################################################################
# update/add packages
RUN apk update && apk add wget grep --no-cache

##########################################################################
# Create working directory and volume mount points
RUN mkdir -p /HDHomeRunDVR && mkdir /dvrdata && mkdir /dvrrec

##########################################################################
# Copy Startup Script into Image, will be run every time container is started
COPY hdhomerun.sh /HDHomeRunDVR
RUN chmod u+x /HDHomeRunDVR/hdhomerun.sh

##########################################################################
##########################################################################
# Add Volume, expose port and entry point
##########################################################################
##########################################################################
FROM builder AS final
# Set Volumes to be added for external mapping
VOLUME ["/dvrdata","/dvrrec"]

# Mapping at least of udp port to docker network (if applicable)
EXPOSE 65001/udp
# not really necessary, as the discovery/engine configuration file will drive the tcp port needed
# EXPOSE 59090

# And setup to run by default
ENTRYPOINT ["/bin/sh","/HDHomeRunDVR/hdhomerun.sh"]
