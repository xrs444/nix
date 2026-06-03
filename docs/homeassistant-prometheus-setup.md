# Home Assistant + Prometheus Integration Setup

This guide walks through integrating Home Assistant with your existing Prometheus monitoring stack on xsvr1.

## Overview

```text
┌─────────────────────────────────────────────────────────────┐
│  Home Assistant                                             │
│  ┌────────────────────────────────────────┐                │
│  │ configuration.yaml                     │                │
│  │   prometheus:                          │                │
│  │     namespace: homeassistant           │                │
│  │     filter: ...                        │                │
│  └────────────────────────────────────────┘                │
│                    │                                        │
│                    │ Exposes /api/prometheus               │
│                    ▼                                        │
│  http://homeassistant.local:8123/api/prometheus            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ (scraped by)
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  Prometheus (xsvr1.lan:9090)                                │
│  ┌────────────────────────────────────────┐                │
│  │ prometheus.nix (scrape_configs)        │                │
│  │                                         │                │
│  │ Authorization: Bearer <token>          │                │
│  │ Token file:                            │                │
│  │   /var/lib/prometheus/homeassistant-token │            │
│  └────────────────────────────────────────┘                │
│                    │                                        │
│                    │ (sends alerts to)                      │
│                    ▼                                        │
│  Alertmanager (xsvr1.lan:9093)                             │
│  ┌────────────────────────────────────────┐                │
│  │ Webhook to Apprise                     │                │
│  │ http://apprise.apprise.svc.cluster.local:8000/notify    │
│  └────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Configure Home Assistant

### 1.1 Enable Prometheus Integration

Add to your Home Assistant `configuration.yaml`:

```yaml
# Prometheus metrics exporter
prometheus:
  namespace: homeassistant

  # Optional: Filter which entities to expose
  filter:
    include_domains:
      - sensor
      - binary_sensor
      - switch
      - light
      - climate
      - cover
      - weather
      - person
      - device_tracker

    # Optional: Exclude specific entities
    exclude_entities:
      - sensor.very_noisy_sensor
      - sensor.high_frequency_update
```

### 1.2 Restart Home Assistant

After editing `configuration.yaml`, restart Home Assistant:

- Via UI: **Settings** → **System** → **Restart**
- Via command line (if running as service): `sudo systemctl restart home-assistant`

### 1.3 Verify Prometheus Endpoint

Test that the metrics endpoint is accessible:

```bash
curl http://homeassistant.local:8123/api/prometheus
```

You should see output starting with:

```text
# HELP homeassistant_sensor_temperature_c Temperature
# TYPE homeassistant_sensor_temperature_c gauge
...
```

## Step 2: Create Home Assistant Long-Lived Access Token

### 2.1 Generate Token in Home Assistant

1. Log into Home Assistant: `http://homeassistant.local:8123`
2. Click your profile in the bottom left
3. Scroll down to **"Long-Lived Access Tokens"**
4. Click **"Create Token"**
5. Name: `Prometheus Monitoring`
6. **Copy the token immediately** - you won't be able to see it again!

The token will look something like:

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI3ZjE4N2E4YjA5YzM0OGU4YTY5MzYwZGUyZmU3MTc5ZiIsImlhdCI6MTY3MDAwMDAwMCwiZXhwIjoxOTg1MzYwMDAwfQ.Xsw_XYz123abc...
```

### 2.2 Store Token in Secrets File

Edit the secrets file:

```bash
cd ~/Repositories/HomeProd/nix/secrets
sops homeassistant-prometheus.yaml
```

Replace `YOUR_TOKEN_HERE` with your actual token:

```yaml
token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI3ZjE4N...
```

Save and exit. The file will be automatically encrypted by sops.

### 2.3 Verify Token is Encrypted

```bash
cat homeassistant-prometheus.yaml
```

You should see encrypted content like:

```yaml
token: ENC[AES256_GCM,data:abc123...,iv:xyz789...,tag:...,type:str]
```

## Step 3: Deploy Token to xsvr1

### 3.1 Extract Token to Prometheus Directory

On xsvr1, create a script to extract the token:

```bash
# SSH to xsvr1
ssh xsvr1

# Create extraction script
sudo tee /usr/local/bin/setup-homeassistant-token.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Extract token from sops-encrypted file
TOKEN=$(sops -d /home/xrs444/Repositories/HomeProd/nix/secrets/homeassistant-prometheus.yaml | grep '^token:' | cut -d' ' -f2-)

# Write to prometheus directory
echo -n "$TOKEN" | sudo tee /var/lib/prometheus/homeassistant-token > /dev/null

# Set proper permissions
sudo chown prometheus:prometheus /var/lib/prometheus/homeassistant-token
sudo chmod 600 /var/lib/prometheus/homeassistant-token

echo "✅ Home Assistant token deployed to /var/lib/prometheus/homeassistant-token"
EOF

# Make executable
sudo chmod +x /usr/local/bin/setup-homeassistant-token.sh

# Run it
sudo /usr/local/bin/setup-homeassistant-token.sh
```

### 3.2 Verify Token File

```bash
# Check file exists and has correct permissions
ls -la /var/lib/prometheus/homeassistant-token

# Should show:
# -rw------- 1 prometheus prometheus 200+ /var/lib/prometheus/homeassistant-token

# Verify token content (should be a long string)
sudo cat /var/lib/prometheus/homeassistant-token
```

### 3.3 Test Token Works

```bash
TOKEN=$(sudo cat /var/lib/prometheus/homeassistant-token)

curl -H "Authorization: Bearer $TOKEN" \
  http://homeassistant.local:8123/api/prometheus | head -20
```

You should see Prometheus metrics output.

## Step 4: Update Prometheus Configuration

The Prometheus scrape configuration has already been added to [prometheus.nix](../modules/services/monitoring/prometheus.nix).

### 4.1 Update Home Assistant Hostname

Edit `prometheus.nix` and update the target if needed:

```nix
# Line ~393
targets = [ "homeassistant.local:8123" ];
# Or use IP: [ "192.168.1.100:8123" ]
```

### 4.2 Deploy Configuration to xsvr1

```bash
# From your local machine (or wherever you manage nix configs)
cd ~/Repositories/HomeProd/nix

# Build and deploy to xsvr1
just deploy-xsvr1

# Or manually:
nixos-rebuild switch --flake .#xsvr1 --target-host xsvr1 --use-remote-sudo
```

### 4.3 Reload Prometheus

```bash
# SSH to xsvr1
ssh xsvr1

# Reload Prometheus (graceful reload without restart)
sudo systemctl reload prometheus

# Or restart if needed
# sudo systemctl restart prometheus
```

## Step 5: Verify Integration

### 5.1 Check Prometheus Targets

1. Open Prometheus UI: `http://xsvr1.lan:9090/targets`
2. Look for the `homeassistant` job
3. State should be **UP** (green)

If DOWN (red), check:

- Home Assistant is accessible from xsvr1
- Token file exists and is readable by prometheus user
- Token is valid

### 5.2 Query Home Assistant Metrics

Go to `http://xsvr1.lan:9090/graph` and try these queries:

```promql
# All Home Assistant metrics
{job="homeassistant"}

# Temperature sensors
homeassistant_sensor_temperature_c

# Battery levels
homeassistant_sensor_battery_percent

# Light states
homeassistant_light_state

# Binary sensors (doors, windows, motion)
homeassistant_binary_sensor_state

# Switch states
homeassistant_switch_state
```

### 5.3 Check Metrics in Grafana

Open Grafana: `http://xsvr1.lan:3000`

Create a dashboard or use Explore to query Home Assistant metrics.

## Step 6: (Optional) Set Up Alerts

### 6.1 Add Home Assistant Alert Rules

Edit `prometheus.nix` and add alert rules (around line 726):

```nix
{
  name = "homeassistant_alerts";
  interval = "60s";
  rules = [
    {
      alert = "HomeAssistantDown";
      expr = "up{job=\"homeassistant\"} == 0";
      for = "5m";
      labels = {
        severity = "critical";
      };
      annotations = {
        summary = "Home Assistant is down";
        description = "Home Assistant has been unreachable for more than 5 minutes.";
      };
    }
    {
      alert = "HighTemperature";
      expr = "homeassistant_sensor_temperature_c > 30";
      for = "10m";
      labels = {
        severity = "warning";
      };
      annotations = {
        summary = "High temperature detected";
        description = "{{ $labels.friendly_name }} is {{ $value }}°C (threshold: 30°C)";
      };
    }
    {
      alert = "LowBattery";
      expr = "homeassistant_sensor_battery_percent < 20";
      for = "1h";
      labels = {
        severity = "warning";
      };
      annotations = {
        summary = "Low battery on {{ $labels.friendly_name }}";
        description = "Battery level is {{ $value }}%";
      };
    }
  ];
}
```

### 6.2 Deploy and Test Alerts

```bash
# Deploy configuration
just deploy-xsvr1

# Check alerts in Prometheus
# http://xsvr1.lan:9090/alerts

# Alerts will automatically route to Apprise via Alertmanager
# Check: http://xsvr1.lan:9093
```

## Apprise Integration (Already Configured)

Your Alertmanager is already configured to send alerts to Apprise:

```yaml
# From prometheus.nix line 782
webhook_configs:
  - url: "http://apprise.apprise.svc.cluster.local:8000/notify?tag=critical-infra"
```

Home Assistant alerts will automatically be sent via:

- **Prometheus** → evaluates alert rules
- **Alertmanager** → routes alerts
- **Apprise** → delivers notifications (ntfy, email, Slack, etc.)

## Loki Integration (Optional) - Home Assistant OS

Since you're running **Home Assistant OS on Raspberry Pi**, you need to use **Add-ons** to ship logs to Loki. You don't have access to the underlying OS for rsyslog/Promtail configuration.

### Option 1: Promtail Add-on (Recommended)

Install the Promtail add-on to ship Home Assistant logs to your Loki instance.

#### Step 1: Install Promtail Add-on

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the **⋮** menu (top right) → **Repositories**
3. Add community repository (if needed): `https://github.com/mdegat01/hassio-addons`
4. Find and install **Promtail** add-on

#### Step 2: Configure Promtail Add-on

In the add-on **Configuration** tab:

```yaml
client:
  url: http://loki.xrs444.net:3100/loki/api/v1/push

scrape_configs:
  - job_name: homeassistant
    static_configs:
      - targets:
          - localhost
        labels:
          job: homeassistant
          host: home-assistant
          __path__: /config/home-assistant.log

  # Optional: Scrape add-on logs
  - job_name: addons
    static_configs:
      - targets:
          - localhost
        labels:
          job: addons
          host: home-assistant
          __path__: /config/addons/**/*.log
```

#### Step 3: Start and Enable

- Click **Start**
- Enable **Start on boot**
- Enable **Watchdog**
- Check **Logs** tab for any errors

### Option 2: Loki Integration (If Available)

Check if there's a direct Loki integration:

1. Go to **Settings** → **Devices & Services** → **Add Integration**
2. Search for "Loki"
3. If available, configure with your Loki URL

### Option 3: Custom Automation (Limited)

For critical events only, you can use REST commands to push specific log entries:

```yaml
# configuration.yaml
rest_command:
  log_to_loki:
    url: "http://loki.xrs444.net:3100/loki/api/v1/push"
    method: POST
    content_type: "application/json"
    payload: >
      {
        "streams": [{
          "stream": {"job": "homeassistant", "level": "{{ level }}"},
          "values": [["{{ now().timestamp() * 1000000000 | int }}", "{{ message }}"]]
        }]
      }

# Example automation
automation:
  - alias: "Log critical errors to Loki"
    trigger:
      - platform: event
        event_type: system_log_event
        event_data:
          level: ERROR
    action:
      - service: rest_command.log_to_loki
        data:
          level: "error"
          message: "{{ trigger.event.data.message }}"
```

**Note:** This option is not recommended for continuous log streaming - use Promtail add-on instead.

### Verify Logs in Loki

After configuring the Promtail add-on:

1. **Query in Grafana:**

   ```promql
   {job="homeassistant"}
   ```

2. **Check Loki directly:**

   ```bash
   curl -G -s "http://loki.xrs444.net:3100/loki/api/v1/query" \
     --data-urlencode 'query={job="homeassistant"}' \
     --data-urlencode 'limit=10' | jq
   ```

### Alternative: Built-in Home Assistant Logging

If log shipping proves difficult, Home Assistant OS has excellent built-in log viewing:

- **System Logs:** Settings → System → Logs (shows HA core and add-on logs)
- **Logbook:** Tracks all entity state changes
- **History:** Built-in time-series data viewer
- **Recorder:** SQLite/PostgreSQL database for historical data

**Important Note:** Home Assistant's `syslog` integration is only for sending *notifications* to local syslog, not for log shipping. For HAOS, you must use add-ons.

## Troubleshooting

### Prometheus Target Shows DOWN

1. **Test connectivity:**
   ```bash
   ssh xsvr1
   curl http://homeassistant.local:8123/api/prometheus
   ```

2. **Check DNS resolution:**
   ```bash
   ping homeassistant.local
   # Or use IP directly in prometheus.nix
   ```

3. **Verify token:**
   ```bash
   TOKEN=$(sudo cat /var/lib/prometheus/homeassistant-token)
   curl -H "Authorization: Bearer $TOKEN" \
     http://homeassistant.local:8123/api/prometheus
   ```

4. **Check Prometheus logs:**
   ```bash
   journalctl -u prometheus -f --since "5 minutes ago"
   ```

### No Metrics Appearing

1. **Check Home Assistant Prometheus integration is enabled**
2. **Restart Home Assistant** after config changes
3. **Verify entities are not all excluded** by filter rules
4. **Check metric names** - they follow pattern `homeassistant_{domain}_{metric}`

### Token Expired or Invalid

1. **Create new token** in Home Assistant
2. **Update secrets file:**
   ```bash
   sops nix/secrets/homeassistant-prometheus.yaml
   ```
3. **Redeploy token:**
   ```bash
   sudo /usr/local/bin/setup-homeassistant-token.sh
   sudo systemctl reload prometheus
   ```

### Permission Denied on Token File

```bash
sudo chown prometheus:prometheus /var/lib/prometheus/homeassistant-token
sudo chmod 600 /var/lib/prometheus/homeassistant-token
sudo systemctl restart prometheus
```

## Summary

You've now integrated Home Assistant with your monitoring stack:

✅ **Prometheus** scrapes Home Assistant metrics every 60 seconds
✅ **Alertmanager** sends Home Assistant alerts to Apprise
✅ **Token** stored securely using sops encryption
✅ **Grafana** can visualize Home Assistant data
✅ **(Optional)** Loki can collect Home Assistant logs

## Next Steps

1. **Create Grafana dashboards** for Home Assistant metrics
2. **Set up custom alerts** for your specific sensors/automations
3. **Configure Apprise tags** for different alert priorities
4. **Explore recording rules** to pre-aggregate commonly queried metrics

## References

- [Home Assistant Prometheus Integration](https://www.home-assistant.io/integrations/prometheus/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Existing Kubernetes Auth Setup](./kubernetes-auth-setup.md)
- [Alerting Guide](./alerting-guide.md)
