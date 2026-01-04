# Glance Configuration Reference

Complete reference for Glance dashboard configuration options.

## Configuration File Structure

Glance configuration uses YAML format in `config/glance.yml`:

```yaml
server:
  port: 8080

branding:
  app-name: Dashboard

theme:
  light: false

pages:
  - name: Home
    columns:
      - size: small | full
        widgets:
          - type: widget-type
            # widget-specific options
```

## Server Configuration

```yaml
server:
  port: 8080          # Internal port (always 8080 in Docker)
  host: 0.0.0.0      # Listen address (default: all interfaces)
```

## Branding

```yaml
branding:
  app-name: Dashboard  # Application title
```

## Theme

```yaml
theme:
  light: false  # false = dark mode, true = light mode
```

## Page Layout

### Column Sizes

- `small`: Sidebar width (~300px), good for navigation/bookmarks
- `full`: Full width, good for data tables/dashboards

### Example Layout

```yaml
pages:
  - name: Home
    columns:
      - size: small        # Left sidebar
        widgets:
          - type: bookmarks
      - size: full         # Main content area
        widgets:
          - type: docker-containers
```

## Widgets

### Docker Containers Widget

Monitor Docker containers with status:

```yaml
- type: docker-containers
  title: Docker Containers
  limit: 20                  # Max containers to show
  running-only: false        # Show all containers (true = running only)
  show-status: true          # Show container status
```

### Bookmarks Widget

Create organized link collections:

```yaml
- type: bookmarks
  groups:
    - title: Group Name
      links:
        - title: Link Title
          url: https://example.com
          icon: mdi:icon-name
```

#### Icon Prefixes

| Prefix | Source | Example |
|--------|--------|---------|
| `si:` | Simple Icons | `si:docker`, `si:github` |
| `mdi:` | Material Design Icons | `mdi:dns`, `mdi:dashboard` |
| `sh:` | selfh.st icons | `sh:service-name` |
| `di:` | Dashboard Icons | `di:service` |

#### Common Service Icons

| Service | Icon |
|---------|------|
| Docker | `si:docker` |
| Dockge | `si:docker` |
| Portainer | `si:portainer` |
| DNS | `mdi:dns` |
| Nginx | `mdi:nginx` |
| Database | `mdi:database` |
| Dashboard | `mdi:view-dashboard` |
| Monitoring | `mdi:monitor-dashboard` |

### RSS Feed Widget

Display RSS/Atom feeds:

```yaml
- type: rss
  title: News
  limit: 10
  feeds:
    - url: https://example.com/feed.xml
      title: Example Feed
```

### Calendar Widget

Show calendar events:

```yaml
- type: calendar
  title: Calendar
  calendars:
    - url: https://calendar.google.com/calendar/ical/...
      color: "#ff0000"
```

### Weather Widget

Display weather information:

```yaml
- type: weather
  location: City, Country
  units: metric  # or imperial
  hour-format: 24  # or 12
  hide-location: false
  show-area-name: true
```

### Monitor Widget

Track website uptime and status:

```yaml
- type: monitor
  title: Service Uptime
  show-failing-only: false
  sites:
    - title: Service Name
      url: https://example.com
      icon: mdi:web
```

### Server Stats Widget

Monitor local and remote server performance:

```yaml
- type: server-stats
  servers:
    - type: local
      name: Home Server
      hide-swap: false
    - type: remote
      name: Remote Server
      url: https://remote.example.com
      token: auth-token
```

### DNS Stats Widget

Display DNS query statistics (supports Technitium, Pi-hole, AdGuard):

```yaml
- type: dns-stats
  service: technitium  # or pihole, adguard
  url: http://dns-server:5380
  username: admin  # optional
  password: password  # optional
  token: api-token  # optional
  hide-graph: false
  hide-top-domains: false
```

### Markets Widget

Track stocks, crypto, and currency pairs:

```yaml
- type: markets
  markets:
    - symbol: BTC-USD
      name: Bitcoin
    - symbol: ETH-USD
      name: Ethereum
    - symbol: USDPLN=X
      name: USD/PLN
    - symbol: DX-Y.NYB
      name: Dollar Index
```

### Releases Widget

Track GitHub/GitLab project releases:

```yaml
- type: releases
  repositories:
    - repository: glanceapp/glance
    - repository: docker/docker
```

### Repository Widget

Display GitHub repository information:

```yaml
- type: repository
  repositories:
    - repository: username/repo
```

### Hacker News Widget

Display stories from Hacker News:

```yaml
- type: hacker-news
  limit: 15
  sort-by: top  # or new
```

### Lobsters Widget

Aggregates content from Lobsters:

```yaml
- type: lobsters
  limit: 15
  instance-url: https://lobste.rs
  tags:
    - linux
    - devops
```

### Reddit Widget

Display subreddit posts:

```yaml
- type: reddit
  subreddit: selfhosted
  limit: 15
  show-thumbnails: true
```

### Videos Widget

Show YouTube channels and playlists:

```yaml
- type: videos
  channels:
    - channel-id
  limit: 10
```

### Twitch Channels Widget

Track Twitch streamers:

```yaml
- type: twitch-channels
  channels:
    - channel-name
```

### Twitch Top Games Widget

Show trending games on Twitch:

```yaml
- type: twitch-top-games
  limit: 10
```

### Clock Widget

Display multiple timezones:

```yaml
- type: clock
  timezones:
    - timezone: Europe/Warsaw
      label: Poland
    - timezone: America/New_York
      label: New York
```

### Todo Widget

Task management:

```yaml
- type: todo
```

### Search Widget

Custom search functionality:

```yaml
- type: search
  search-engine: https://www.google.com/search?q={QUERY}
```

### Custom API Widget

Fetch and display custom API data:

```yaml
- type: custom-api
  url: https://api.example.com/data
  refresh-interval: 300
```

### Extension Widget

Load external HTML content:

```yaml
- type: extension
  url: https://example.com/widget.html
```

### iframe Widget

Embed external web content:

```yaml
- type: iframe
  url: https://example.com
  height: 400
```

### HTML Widget

Render custom HTML:

```yaml
- type: html
  content: |
    <h1>Custom Content</h1>
    <p>HTML goes here</p>
```

### ChangeDetection.io Widget

Track website changes:

```yaml
- type: change-detection
  instance-url: https://changedetection.io
  token: your-token
  watches:
    - uuid: watch-id
```

### Group Widget

Organize multiple widgets together:

```yaml
- type: group
  widgets:
    - type: weather
      location: City
    - type: clock
```

## Complete Example Configuration

```yaml
server:
  port: 8080

branding:
  app-name: My Dashboard

theme:
  light: false

pages:
  - name: Home
    columns:
      # Left sidebar with bookmarks
      - size: small
        widgets:
          - type: bookmarks
            groups:
              - title: Container Management
                links:
                  - title: Dockge
                    url: http://192.168.1.55:5001
                    icon: si:docker

              - title: Services
                links:
                  - title: TechnitiumDNS
                    url: http://192.168.1.55:5380
                    icon: mdi:dns

                  - title: Glance
                    url: http://192.168.1.55
                    icon: mdi:view-dashboard

      # Main content area
      - size: full
        widgets:
          - type: docker-containers
            title: Docker Containers
            limit: 20
            running-only: false
            show-status: true

          - type: rss
            title: Tech News
            limit: 5
            feeds:
              - url: https://news.ycombinator.com/rss
                title: Hacker News

          - type: monitor
            title: Service Uptime
            sites:
              - title: Dockge
                url: http://192.168.1.55:5001
                icon: si:docker
              - title: TechnitiumDNS
                url: http://192.168.1.55:5380
                icon: mdi:dns

          - type: weather
            location: Lodz, Poland
            units: metric

          - type: markets
            markets:
              - symbol: BTC-USD
                name: Bitcoin
              - symbol: ETH-USD
                name: Ethereum

          - type: server-stats
            servers:
              - type: local
                name: Host Server

          - type: dns-stats
            service: technitium
            url: http://192.168.1.55:5380
```

## Service Port Reference

Common Docker service ports for bookmarks:

| Service | Default Port | URL |
|---------|--------------|-----|
| Dockge | 5001 | http://IP:5001 |
| TechnitiumDNS | 5380 | http://IP:5380 |
| Portainer | 9000 | http://IP:9000 |
| Nginx Proxy Manager | 81 | http://IP:81 |
| Uptime Kuma | 3001 | http://IP:3001 |
| Grafana | 3000 | http://IP:3000 |
| Prometheus | 9090 | http://IP:9090 |
| Pi-hole | 80 | http://IP/admin |
| Home Assistant | 8123 | http://IP:8123 |
| Jellyfin | 8096 | http://IP:8096 |

## Configuration Tips

### Auto-Reload

Glance automatically reloads configuration when `config/glance.yml` changes. No container restart needed.

### Multiple Pages

Create multiple pages for organization:

```yaml
pages:
  - name: Overview
    columns: [...]

  - name: Monitoring
    columns: [...]
```

### Conditional Content

Use environment variables in configuration:

```yaml
branding:
  app-name: ${APP_NAME:-Dashboard}  # Use env var or default
```

## Troubleshooting

### Config Not Loading

**Check**: File is in `config/glance.yml` (not root directory)

**Check**: Volume mount is `./config:/app/config` in compose.yaml

**Check**: YAML syntax is valid (use yamllint)

### Widgets Not Showing

**Check**: Widget type spelling (e.g., `docker-containers` not `docker_containers`)

**Check**: Required fields present for widget type

**Check**: Logs: `docker logs glance`

### Docker Containers Empty

**Check**: Docker socket mounted: `/var/run/docker.sock:/var/run/docker.sock:ro`

**Check**: Containers are running: `docker ps`

**Check**: Permissions on socket

## External Resources

- Official docs: https://github.com/glanceapp/glance/blob/main/docs/configuration.md
- v0.7.0 upgrade guide: https://github.com/glanceapp/glance/blob/main/docs/v0.7.0-upgrade.md
- Icon search:
  - Material Design: https://pictogrammers.com/library/mdi/
  - Simple Icons: https://simpleicons.org
