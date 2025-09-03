#!/bin/bash
PROMETHEUS_VERSION="3.5.0"
PROMETHEUS_CONFIG_DIRECTORY="/etc/prometheus"
PROMETHEUS_DATA_DIRECTORY="/etc/prometheus/data"
read -p "Specify the port for prometheus (if you don't know what to set, set 9090):" PORT


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
rm -rf /tmp/prometheus*

cat <<EOF >$PROMETHEUS_CONFIG_DIRECTORY/prometheus.yml
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:$PORT"]
       # The label name is added as a label `label_name=<label_value>` to any timeseries scraped from this config.
        labels:
          app: "prometheus"
EOF

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
ExecStart=/usr/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /etc/prometheus/data --web.listen-address=:$PORT
  
[Install]  
WantedBy=multi-user.target  
EOF

getenforce && semanage fcontext -a -t bin_t "/usr/bin/prometheus" && restorecon -Rv /usr/bin/prometheus

systemctl daemon-reload
systemctl enable --now prometheus.service
systemctl status prometheus --no-pager
prometheus --version
