FROM ubuntu:18.04

ENV VPNADDR \
    VPNUSER \
    VPNPASS \
    VPNTIMEOUT

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y -o APT::Install-Recommends=false -o APT::Install-Suggests=false \
  ca-certificates \
  expect \
  net-tools \
  iproute2 \
  ipppd \
  iptables \
  wget \
  nano
  # \
  # && apt-get clean -q && apt-get autoremove --purge \
  # && rm -rf /var/lib/apt/lists/*

WORKDIR /root
USER root
# Install fortivpn client unofficial .deb
RUN wget 'https://hadler.me/files/forticlient-sslvpn_4.4.2329-1_amd64.deb' -O forticlient-sslvpn_amd64.deb
RUN dpkg -x forticlient-sslvpn_amd64.deb /usr/share/forticlient && rm forticlient-sslvpn_amd64.deb

# Run setup
RUN /usr/share/forticlient/opt/forticlient-sslvpn/64bit/helper/setup.linux.sh 2

# Copy runfiles
COPY forticlient /usr/bin/forticlient
COPY start.sh /start.sh

CMD [ "/start.sh" ]

# CMD [ "./forticlientsslvpn_cli  --server ${VPNADDR} --vpnuser ${VPNUSER}" ]
