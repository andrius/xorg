FROM debian:stretch-slim

LABEL maintainer="\"Andrius Kairiukstis\" <k@andrius.mobi>"

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY :1
ENV VNC_PORT 5901
ENV NO_VNC_PORT 6901
EXPOSE $VNC_PORT $NO_VNC_PORT

ENV HOME /headless
ENV STARTUPDIR /dockerstartup
WORKDIR $HOME

# Envrionment config
ENV NO_VNC_HOME $HOME/noVNC
ENV VNC_COL_DEPTH 24
ENV VNC_RESOLUTION 1280x1024
ENV VNC_PW vncpassword

# Add all install scripts for further steps
ENV INST_SCRIPTS $HOME/.install-scripts
ADD ./install-scripts $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

# Install some common tools and xorg stuff
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
\
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     sudo \
     gnupg2 \
     iproute2 \
     ntp \
     wget \
     ca-certificates \
\
&& echo "Installing IceWM and xorg" \
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     supervisor \
     dbus \
     dbus-x11 \
     x11-xserver-utils \
     xfonts-base \
     xauth \
     xinit \
     xserver-xorg-video-dummy \
     icewm \
     terminator \
     pcmanfm \
&& apt-get purge -yqq pm-utils xscreensaver* \
&& mkdir -p ~/.config/terminator \
&& touch ~/.config/terminator/config \
\
&& echo "Installing TigerVNC" \
&& wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C / \
\
&& echo "Installing noVNC" \
&& mkdir -p $NO_VNC_HOME/utils/websockify \
&& wget -qO- https://github.com/kanaka/noVNC/archive/v0.6.2.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME \
&& wget -qO- https://github.com/kanaka/websockify/archive/v0.8.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify \
&& chmod +x -v $NO_VNC_HOME/utils/*.sh \
&& ln -s $NO_VNC_HOME/vnc_auto.html $NO_VNC_HOME/index.html \
\
&& echo "Installing Chrome" \
&& wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - \
&& echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list \
&& apt-get update \
&& apt-get -yqq --no-install-suggests --no-install-recommends install \
     google-chrome-stable; apt-get -yqq -f --no-install-suggests --no-install-recommends install \
\
&& echo "Cleaning system" \
&& apt-get clean all && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man* /tmp/* /var/tmp/*
ENV DEBIAN_FRONTEND interactive

### Install IceWM UI
ADD ./icewm/ $HOME/

# ### configure startup
# RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./startup-scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--tail-log"]
