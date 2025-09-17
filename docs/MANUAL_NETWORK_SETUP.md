# Manual Network Configuration for Workshop Environment

This guide explains how to configure network connectivity manually when the GUI network manager is not available or when setting up the workshop environment offline.

## Prerequisites

- Root or sudo access
- Basic command line knowledge
- Network interface name (usually `eth0`, `wlan0`, etc.)

## Quick Network Diagnosis

```bash
# Check network interfaces
ip addr show

# Check NetworkManager status
systemctl status NetworkManager

# Check current connections
nmcli connection show

# Check device status
nmcli device status

# Test internet connectivity
ping -c 3 8.8.8.8
curl -I https://abra.coopcloud.tech
```

## Manual WiFi Connection

### Method 1: Using nmcli (Command Line)

```bash
# Scan for WiFi networks
nmcli device wifi list

# Connect to a WiFi network (replace SSID and PASSWORD)
nmcli device wifi connect "YourWiFiSSID" password "YourWiFiPassword"

# Connect to hidden network
nmcli device wifi connect "HiddenSSID" password "password" hidden yes

# Check connection status
nmcli connection show --active
```

### Method 2: Using wpa_supplicant (Advanced)

```bash
# Create wpa_supplicant configuration
sudo tee /etc/wpa_supplicant.conf > /dev/null <<EOF
network={
    ssid="YourWiFiSSID"
    psk="YourWiFiPassword"
}
EOF

# Connect using wpa_supplicant
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
sudo dhclient wlan0
```

## Manual Ethernet Connection

```bash
# Bring interface up
sudo ip link set eth0 up

# Get IP via DHCP
sudo dhclient eth0

# Or set static IP
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add default via 192.168.1.1
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

## Workshop-Specific Network Setup

### Workshop WiFi (Automatic)

The workshop environment automatically connects to the "CODE_CRISPIES" WiFi network using declarative NetworkManager configuration. No manual setup is required.

If you need to connect to a different network:

```bash
# Connect to workshop hotspot (if available)
nmcli device wifi connect "CODE_CRISPIES" password "scienceinthecity2025"
```

### Configure Local DNS Resolution

```bash
# Ensure dnsmasq is running for local DNS
sudo systemctl start dnsmasq
sudo systemctl enable dnsmasq

# Test local DNS
nslookup traefik.workshop.local 127.0.0.1
```

## Offline Setup Workflow

When internet is not available during workshop setup:

1. **Network Connects Automatically**
    ```bash
    # WiFi connects automatically to "CODE_CRISPIES" on boot
    # Check connection: nmcli connection show --active
    ```

2. **Skip Online Dependencies**
    ```bash
    # The setup script will work offline once network is configured
    setup
    ```

3. **Manual abra Installation** (if needed)
   ```bash
   # Use the install command (preferred)
   install

   # Or manually restart the service
   sudo systemctl restart workshop-abra-install

   # Check installation status
   sudo systemctl status workshop-abra-install
   sudo abra --version
   ```

4. **Deploy Local Services**
   ```bash
   # Deploy services that don't require internet
   deploy gitea  # Local git server
   deploy nextcloud  # Local file sharing
   ```

## Troubleshooting

### NetworkManager Issues

```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Reconnect to network
nmcli connection up "connection-name"

# Delete problematic connection
nmcli connection delete "connection-name"
```

### DNS Issues

```bash
# Flush DNS cache
sudo systemctl restart dnsmasq

# Check DNS resolution
dig @127.0.0.1 workshop.local

# Manual DNS test
nslookup google.com 8.8.8.8
```

### Firewall Issues

```bash
# Check firewall status (should be disabled for workshop)
sudo ufw status
sudo iptables -L

# Temporarily disable firewall (if interfering)
sudo ufw disable
```

## GUI Network Manager

If the GUI is available:

1. Click the network icon in the top-right corner
2. Select "Settings" or "Wi-Fi Settings"
3. Choose your network from the list
4. Enter password if required
5. The connection should be established automatically

## Advanced Configuration

### Create Custom Network Profile

```bash
# Create a new connection profile
nmcli connection add type wifi con-name "MyWorkshopNetwork" ifname wlan0 ssid "WorkshopWiFi"

# Configure the connection
nmcli connection modify "MyWorkshopNetwork" wifi-sec.key-mgmt wpa-psk
nmcli connection modify "MyWorkshopNetwork" wifi-sec.psk "workshoppassword"

# Set as autoconnect
nmcli connection modify "MyWorkshopNetwork" connection.autoconnect yes
```

### Static IP Configuration

```bash
# Set static IP for workshop environment
nmcli connection modify "MyWorkshopNetwork" ipv4.method manual
nmcli connection modify "MyWorkshopNetwork" ipv4.addresses "192.168.100.10/24"
nmcli connection modify "MyWorkshopNetwork" ipv4.gateway "192.168.100.1"
nmcli connection modify "MyWorkshopNetwork" ipv4.dns "8.8.8.8,1.1.1.1"
```

## Emergency Network Access

If all else fails, you can use USB tethering:

1. Connect phone via USB
2. Enable USB tethering on phone
3. The connection should appear as `usb0` or similar
4. Configure as above using `nmcli` or GUI

## Testing Your Setup

```bash
# Test basic connectivity
ping 8.8.8.8

# Test DNS
nslookup google.com

# Test abra installation
sudo abra --version

# Test abra connectivity
sudo abra server ls

# Test workshop services
curl http://traefik.workshop.local
```

## Getting Help

- Run `network_help` in the workshop terminal for quick reference
- Check system logs: `journalctl -u NetworkManager`
- Use `nmcli --help` for detailed command options