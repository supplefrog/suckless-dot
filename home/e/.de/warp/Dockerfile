FROM rockylinux/rockylinux:9-ubi-init

RUN dnf -y update && \
    dnf -y install dnf libcurl mesa-libEGL mesa-dri-drivers vulkan-loader --allowerasing && \
    dnf clean all

COPY warp-terminal*.rpm /tmp/warp-terminal.rpm

RUN dnf -y install /tmp/warp-terminal.rpm && rm -f /tmp/warp-terminal.rpm

# Set the DISPLAY variable for X11 forwarding
ENV DISPLAY=:0

# Optional: Use a script to start dbus and warp-terminal
COPY start-warp.sh /usr/local/bin/start-warp.sh
RUN chmod +x /usr/local/bin/start-warp.sh

CMD ["/usr/local/bin/start-warp.sh"]

