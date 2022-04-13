FROM almalinux/8-init
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget lsof telnet bind-utils tar tcpdump vim strace less python3
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
ENV container docker
STOPSIGNAL SIGRTMIN+3
RUN rm -f /lib/systemd/system/sysinit.target.wants/sys-fs-fuse-connections.mount
CMD [ "/sbin/init" ]
