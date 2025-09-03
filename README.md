# Prometheus Installation Script

This Bash script automates the installation of Prometheus on a Linux system.

## ⚠️ Warning

This script must be run with **root** privileges (using `sudo`).

## ⚙️ Usage

1.  Make the script executable:
    ```bash
    chmod +x prometheus-install.sh
    ```
2.  Run the script:
    ```bash
    sudo ./prometheus-install.sh
    ```

## 📋 What the Script Does

1.  **Permission Check**: Verifies that the script is being run with `sudo`.
2.  **Download**: Downloads the Prometheus binaries from GitHub.
3.  **Extraction**: Unpacks the downloaded archive.
4.  **Installation**:
    * Moves the `prometheus` executable to `/usr/bin`.
    * Creates directories for configuration and data: `/etc/prometheus` and `/etc/prometheus/data`.
    * Moves the default `prometheus.yml` configuration file to `/etc/prometheus`.
5.  **User Setup**:
    * Creates a non-login system user named `prometheus` for securely running the service.
    * Assigns ownership of all necessary files and directories to this user.
6.  **Systemd Configuration**:
    * Creates a `prometheus.service` file in `/etc/systemd/system/`.
    * Configures the service to run as the `prometheus` user.
7.  **SELinux**:
    * If SELinux is enabled (`getenforce`), the script configures the security context for the Prometheus binary.
8.  **Service Startup**:
    * Reloads the `systemd daemon`.
    * Enables and starts the Prometheus service.
    * Displays the service status and the Prometheus version.

## 📝 Configuration

After the script completes, you can modify the `prometheus.yml` file in the `/etc/prometheus` directory to customize your monitoring system. After making changes, restart the service with the following command:

```bash
sudo systemctl restart prometheus
