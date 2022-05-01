#!/bin/bash
set -e

FOLDERS="/srv/airsonic/music /srv/airsonic/podcasts /srv/airsonic/playlists"

chown -R app_airsonic:root $FOLDERS
find $FOLDERS -type d -exec chmod 750 {} \;
find $FOLDERS -type f -exec chmod 640 {} \;
