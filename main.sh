#!/bin/bash

# Check for supported OS
SUPPORTED_OS=("debian" "ubuntu" "centos" "fedora" "arch")
if ! [[ "${SUPPORTED_OS[*]}" =~ "$(cat /etc/os-release | grep -E '^ID=' | cut -d= -f2)" ]]; then
  echo "Error: This script only supports Debian, Ubuntu, CentOS, Fedora, and Arch Linux."
  exit 1
fi

# Install dependencies
if [[ "$(cat /etc/os-release | grep -E '^ID=' | cut -d= -f2)" == "debian" ]] || \
   [[ "$(cat /etc/os-release | grep -E '^ID=' | cut -d= -f2)" == "ubuntu" ]]; then
  apt update
  apt install -y curl
  apt install -y unzip
elif [[ "$(cat /etc/os-release | grep -E '^ID=' | cut -d= -f2)" == "centos" ]] || \
     [[ "$(cat /etc/os-release | grep -E '^ID=' | cut -d= -f2)" == "fedora" ]]; then
  yum install -y curl
  yum install -y unzip
elif [[ "$(cat /etc/os-release | grep -E '^ID=' | cut -d= -f2)" == "arch" ]]; then
  pacman -Syu
  pacman -S --noconfirm curl
  pacman -S --noconfirm unzip
fi

# Download and install V2Ray
curl -L -O https://github.com/v2ray/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip v2ray-linux-64.zip
rm -rf v2ray-linux-64.zip
chmod +x v2ray

# Generate a random subdomain for camouflage
SUBDOMAIN="$(head /dev/urandom | tr -dc a-z0-9 | head -c 10).example.com"
# Configure SNI proxy with V2Ray
# Configure SNI proxy with V2Ray
cat >config.json <<EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "b831381d-6324-4d53-ad4f-8cda48b30811",
            "flow": "xtls-rprx-origin"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "serverName": "${SUBDOMAIN}",
          "alpn": ["h2"],
          "certificates": [
            {
              "certificateFile": "/path/to/certificate.crt",
              "keyFile": "/path/to/private.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "grpc",
      "settings": {
        "serviceName": "example_service",
        "path": "/api",
        "transportSettings": {
          "security": "tls",
          "tlsSettings": {
            "serverName": "${SUBDOMAIN}",
            "allowInsecure": false,
            "alpn": ["h2"]
          }
        }
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "serverName": "${SUBDOMAIN}",
          "AllowInsecure": false,
      "alpn": ["h2"],
      "certificates": [
        {
          "certificateFile": "/path/to/certificate.crt",
          "keyFile": "/path/to/private.key"
        }
      ]
    }
  },
  "tag": "out"
}
]
}
EOF

# Start V2Ray
nohup ./v2ray -config config.json > v2ray.log 2>&1 &
echo "V2Ray SNI proxy with gRPC is now running on port 443."
