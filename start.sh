#!/usr/bin/env bash

# 1280x1024 defauly
# 1365x1024 best on ipad pro (full resolution is 2048x1536)
docker run -ti --rm \
  -e VNC_RESOLUTION=1364x1024 \
  -p 127.0.0.1:5901:5901 \
  -p 127.0.0.1:6901:6901 \
  --name=xorg \
  xorg

