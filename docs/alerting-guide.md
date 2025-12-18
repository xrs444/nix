# Prometheus Alerting Configuration Guide

## Overview

Alerting in Prometheus consists of two components:
1. **Alert Rules** in Prometheus - Define when alerts should fire
2. **Alertmanager** - Handles alert notifications and routing

Your setup now includes:
- ✅ Basic alert rules for nodes and Kubernetes
- ✅ Alertmanager service enabled
- ✅ Firewall configured for Alertmanager (:9093)

## Current Alert Rules

### Node Alerts

- **InstanceDown**: Fires when a monitored host is unreachable for 5+ minutes
- **HighCPUUsage**: CPU usage above 80% for 10+ minutes
- **HighMemoryUsage**: Memory usage above 90% for 10+ minutes
- **DiskSpaceLow**: Filesystem below 10% free space

### Kubernetes Alerts

- **KubernetesPodCrashLooping**: Pod restarting repeatedly
- **KubernetesPodNotReady**: Pod not in Running/Succeeded state for 15+ minutes
- **KubernetesNodeNotReady**: K8s node not ready for 5+ minutes

## Configuring Notifications

You need to configure receivers in Alertmanager to actually send notifications.

### Option 1: Email Notifications

Edit `nix/modules/services/monitoring/prometheus.nix`, find the `receivers` section:

```nix
receivers = [
  {
    name = "default";
    email_configs = [
      {
        to = "your-email@example.com";
        from = "prometheus@xsvr1.local";
        smarthost = "smtp.example.com:587";
        auth_username = "your-smtp-user";
        auth_password = "your-smtp-password";  # Better: use secrets
        require_tls = true;
      }
    ];
  }
  {
    name = "critical";
    email_configs = [
      {
        to = "critical-alerts@example.com";
        from = "prometheus@xsvr1.local";
        smarthost = "smtp.example.com:587";
        auth_username = "your-smtp-user";
        auth_password = "your-smtp-password";
        require_tls = true;
      }
    ];
  }
];
```

### Option 2: Slack Notifications

```nix
receivers = [
  {
    name = "default";
    slack_configs = [
      {
        api_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK";
        channel = "#monitoring";
        title = "Prometheus Alert";
        text = "{{ range .Alerts }}{{ .Annotations.description }}
{{ end }}";
      }
    ];
  }
];
```

### Option 3: Discord Notifications

```nix
receivers = [
  {
    name = "default";
    discord_configs = [
      {
        webhook_url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL";
        title = "{{ .GroupLabels.alertname }}";
        message = "{{ range .Alerts }}{{ .Annotations.summary }}
{{ end }}";
      }
    ];
  }
];
```

### Option 4: Pushover (Mobile Notifications)

```nix
receivers = [
  {
    name = "default";
    pushover_configs = [
      {
        user_key = "YOUR_USER_KEY";
        token = "YOUR_APP_TOKEN";
        priority = "0";  # -2 to 2, 2 is emergency
        title = "{{ .GroupLabels.alertname }}";
        message = "{{ range .Alerts }}{{ .Annotations.summary }}
{{ end }}";
      }
    ];
  }
];
```

### Option 5: Telegram Notifications

```nix
receivers = [
  {
    name = "default";
    telegram_configs = [
      {
        bot_token = "YOUR_BOT_TOKEN";  # Get from @BotFather
        chat_id = YOUR_CHAT_ID;        # Your chat/channel ID (number)
        parse_mode = "HTML";
        message = ''
{{ range .Alerts }}
<b>{{ .Labels.severity | toUpper }}</b>: {{ .Labels.alertname }}
{{ .Annotations.summary }}
{{ .Annotations.description }}
Instance: {{ .Labels.instance }}
{{ end }}
        '';
      }
    ];
  }
  {
    name = "critical";
    telegram_configs = [
      {
        bot_token = "YOUR_BOT_TOKEN";
        chat_id = YOUR_CHAT_ID;
        parse_mode = "HTML";
        disable_notifications = false;  # Enable sound for critical
        message = ''
🚨 <b>CRITICAL ALERT</b> 🚨
{{ range .Alerts }}
<b>{{ .Labels.alertname }}</b>
{{ .Annotations.summary }}
{{ .Annotations.description }}
Instance: {{ .Labels.instance }}
{{ end }}
        '';
      }
    ];
  }
];
```

**Setup Steps:**

1. **Create a Telegram Bot:**
   - Message [@BotFather](https://t.me/BotFather) on Telegram
   - Send `/newbot` and follow the prompts
   - You'll receive a bot token like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`

2. **Get Your Chat ID:**
   - Start a chat with your new bot
   - Send any message to it
   - Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   - Find your `chat_id` in the JSON response (it's a number)
   - Or use [@userinfobot](https://t.me/userinfobot) to get your chat ID

3. **For Channel/Group Alerts:**
   - Add your bot to the channel/group as an admin
   - Get the channel ID (negative number for groups/channels)
   - Use that as `chat_id`

### Option 6: Webhook (Custom Integration)

```nix
receivers = [
  {
    name = "default";
    webhook_configs = [
      {
        url = "http://your-webhook-endpoint:8080/alerts";
        send_resolved = true;
      }
    ];
  }
];
```

## Telegram Example (Complete)

Here's a complete working example for your `prometheus.nix`:

```nix
receivers = [
  {
    name = "default";
    telegram_configs = [
      {
        bot_token = "123456789:ABCdefGHIjklMNOpqrsTUVwxyz";
        chat_id = 987654321;  # Your personal chat ID
        parse_mode = "HTML";
      }
    ];
  }
  {
    name = "critical";
    telegram_configs = [
      {
        bot_token = "123456789:ABCdefGHIjklMNOpqrsTUVwxyz";
        chat_id = 987654321;
        parse_mode = "HTML";
        disable_notifications = false;
        message = ''🚨 <b>CRITICAL</b>: {{ .GroupLabels.alertname }}'';
      }
    ];
  }
];
```

**Note:** For better security, use secrets management (see below) instead of hardcoding tokens.

## Secrets Management (Recommended)

Instead of hardcoding bot tokens and passwords in your Nix config, use agenix or sops-nix:

### Example with agenix

1. **Create encrypted secret:**
   ```bash
   echo "smtp_password: your-password-here" | agenix -e alertmanager-smtp.age
   ```

2. **Reference in configuration:**
   ```nix
   age.secrets.alertmanager-smtp.file = ../../secrets/alertmanager-smtp.age;

   services.alertmanager = {
     configuration = {
       receivers = [
         {
           name = "default";
           email_configs = [
             {
               auth_password_file = config.age.secrets.alertmanager-smtp.path;
               # ... other config
             }
           ];
         }
       ];
     };
   };
   ```

## Testing Alerts

### 1. Check Prometheus Rules

Visit: <http://xsvr1:9090/rules>

You should see your alert rules loaded.

### 2. Check Alertmanager

Visit: <http://xsvr1:9093>

View active alerts and notification status.

### 3. Manually Trigger a Test Alert

Create a test alert in Prometheus config:

```nix
{
  alert = "TestAlert";
  expr = "vector(1)";  # Always fires
  labels = { severity = "info"; };
  annotations = {
    summary = "This is a test alert";
  };
}
```

### 4. Send Test Notification via CLI

```bash
ssh thomas-local@xsvr1
curl -H "Content-Type: application/json" -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "info"
    },
    "annotations": {
      "summary": "Manual test alert"
    }
  }
]' http://localhost:9093/api/v1/alerts
```

## Advanced Configuration

### Silence Alerts

Temporarily silence alerts via Alertmanager UI or CLI:

```bash
# Silence for 2 hours
amtool silence add alertname=HighCPUUsage --duration=2h --comment="Maintenance window"
```

### Alert on ZFS Issues

Add to alert rules:

```nix
{
  alert = "ZFSPoolDegraded";
  expr = "zfs_pool_health != 0";
  for = "5m";
  labels = { severity = "critical"; };
  annotations = {
    summary = "ZFS pool {{ $labels.pool }} is degraded";
    description = "Pool health status is not ONLINE";
  };
}
```

### Time-based Routing

Route alerts differently based on time of day:

```nix
route = {
  routes = [
    {
      match = {
        severity = "critical";
      };
      receiver = "critical";
      # Business hours only
      active_time_intervals = [ "business-hours" ];
    }
    {
      match = {
        severity = "critical";
      };
      receiver = "on-call";
      # After hours
      active_time_intervals = [ "after-hours" ];
    }
  ];
};

time_intervals = [
  {
    name = "business-hours";
    time_intervals = [
      {
        weekdays = [ "monday:friday" ];
        times = [
          {
            start_time = "09:00";
            end_time = "17:00";
          }
        ];
      }
    ];
  }
];
```

## Deployment

After configuring notifications:

```bash
cd nix
git add -A
git commit -m "Configure Prometheus alerting"
git push

# Deploy to xsvr1
ssh thomas-local@xsvr1
cd /etc/nixos
sudo nixos-rebuild switch --flake .#xsvr1
```

## Verification

1. **Check Prometheus loaded rules:**
   ```bash
   curl http://localhost:9090/api/v1/rules | jq
   ```

2. **Check Alertmanager status:**
   ```bash
   curl http://localhost:9093/api/v1/status | jq
   ```

3. **View active alerts:**
   ```bash
   curl http://localhost:9093/api/v1/alerts | jq
   ```

## Grafana Integration

Alertmanager integrates with Grafana automatically. In Grafana:

1. Go to Alerting → Alert rules
2. You'll see Prometheus/Alertmanager alerts
3. Create dashboards with alert status panels

## Common Alert Expressions

### High Disk I/O
```promql
rate(node_disk_io_time_seconds_total[5m]) > 0.8
```

### Network Saturation
```promql
rate(node_network_receive_bytes_total[5m]) > 100000000  # 100MB/s
```

### Service Down
```promql
up{job="my-service"} == 0
```

### Container Memory Limit
```promql
container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
```

## References

- [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Notification Template Examples](https://prometheus.io/docs/alerting/latest/notification_examples/)
