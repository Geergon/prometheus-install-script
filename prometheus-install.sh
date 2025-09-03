#!/bin/bash
PROMETHEUS_VERSION="3.5.0"
PROMETHEUS_CONFIG_DIRECTORY="/etc/prometheus"
PROMETHEUS_DATA_DIRECTORY="/etc/prometheus/data"

if [ "$EUID" -ne 0 ] || [ -z "$SUDO_USER" ]; then
  echo "Please run this script with 'sudo'"
  exit 1
fi

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar xfvz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

mv prometheus /usr/bin
mkdir -p $PROMETHEUS_CONFIG_DIRECTORY $PROMETHEUS_DATA_DIRECTORY
mv prometheus.yml $PROMETHEUS_CONFIG_DIRECTORY
rm -rf /tmp/prometheus*

# cat <<EOF >$PROMETHEUS_CONFIG_DIRECTORY/prometheus.yml
# global:
#   scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
#
# scrape_configs:
#   - job_name: "prometheus"
#     static_configs:
#       - targets: ["localhost:9090"]
# EOF

useradd -rs /bin/false prometheus
chown prometheus:prometheus /usr/bin/prometheus
chown prometheus:prometheus $PROMETHEUS_CONFIG_DIRECTORY
chown -R prometheus:prometheus $PROMETHEUS_DATA_DIRECTORY

cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]  
Description=Prometheus Server  
After=network.target  
  
[Service]  
User=prometheus  
Group=prometheus  
Type=simple  
Restart=on-failure  
ExecStart=/usr/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /etc/prometheus/data --web.listen-address=:9010
  
[Install]  
WantedBy=multi-user.target  
EOF

getenforce && semanage fcontext -a -t bin_t "/usr/bin/prometheus" && restorecon -Rv /usr/bin/prometheus

systemctl daemon-reload
systemctl enable --now prometheus.service
systemctl status prometheus --no-pager
prometheus --version
