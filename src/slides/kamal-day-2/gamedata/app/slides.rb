module KittenPhoto
  IMAGE = 'sprites/raoul-droog-yMSecCHsIBc-unsplash.jpg'.freeze
  NATURAL_WH = [3024, 4032].freeze
  ATTRIBUTION = {
    tone: :light,
    segments: [
      { text: 'Photo by ' },
      { text: 'Raoul Droog',
        url: 'https://unsplash.com/@raouldroog?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText' },
      { text: ' on ' },
      { text: 'Unsplash',
        url: 'https://unsplash.com/photos/russian-blue-cat-wearing-yellow-sunglasses-yMSecCHsIBc?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText' } # rubocop:disable Layout/LineLength
    ]
  }.freeze
end

class TitleSlide < Slide
  def slide_primitives
    centered_primitives(
      title: 'Deploying with Kamal',
      accent: 'Day 2',
      subtitle: 'Ongoing Maintenance, Observability, and Security'
    )
  end
end

class WhoAmISlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Who Am I?',
      lead: 'Marc Heiligers',
      bullets: [
        'Ex-CTO, 26 years professional development, 16 years Ruby',
        'Organizer of RubyFuZA and RubyDCamp-ZA',
        'Principal Consultant of FASCINATION•works',
        'Co-founder of Bloomlight.app'
      ]
    )
  end
end

class Day0ProfitSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Kamal Deployment',
      lead: 'Kamal makes it super easy to deply Rails (or other) apps:',
      bullets: [
        'Buy a VPS',
        'run `kamal setup`',
        'Profit!'
      ]
    )
  end
end

class Day2ProblemSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'The "Day 2" Problem',
      lead: 'But what about Day 2 and beyond?',
      bullets: [
        'Who patches the OS kernel?',
        'How do we know when Sidekiq runs out of memory?',
        'What happens if the server reboots?',
        'Is SSH really secure on a public port?'
      ]
    )
  end
end

class BeyondBasicsSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Going Beyond the Basics',
      lead: 'Kamal deploys the containers beautifully — we still manage the box underneath.',
      bullets: [
        'Self-hosted observability & alerting',
        'Zero-trust access (WireGuard VPN)',
        'Server maintenance & hardening',
        'Automated provisioning'
      ]
    )
  end
end

class ObservabilityGoalSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: '1. Observability: The Goal',
      lead: 'Know the server is running out of resources before the application goes down.',
      bullets: [
        'Prometheus — time-series data',
        'Grafana — visualizations',
        'Node Exporter — host-level metrics',
        'App metrics — Puma traffic, Sidekiq queues'
      ],
      note: 'All deployed as Kamal accessories.'
    )
  end
end

class ContainerNameProblemSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'The Container Name Problem',
      lead: 'Kamal appends a changing Git SHA to container names on every deploy:',
      bullets: [
        'magnolia_monitor-web-854a84ff9928c053…',
        'How do we tell Prometheus what to scrape when the target name changes constantly?'
      ],
      note: "We can't use static targets for app containers."
    )
  end
end

class ServiceDiscoverySlide < Slide
  def slide_primitives
    code_panel_primitives(
      title: 'Service Discovery to the Rescue',
      lead: "Prometheus's docker_sd_configs + Docker labels. In our Kamal deploy.yml:",
      code_lines: [
        'servers:',
        '  web:',
        '    labels:',
        '      prometheus-scrape: "true"',
        '  job:',
        '    labels:',
        '      prometheus-scrape: "true"'
      ],
      note: 'Prometheus watches the Docker socket and discovers labelled containers. No config changes after a deploy.'
    )
  end
end

class PrometheusDiscoveryConfigSlide < Slide
  def slide_primitives
    code_panel_primitives(
      title: 'Detail: Docker Service Discovery',
      lead: 'Prometheus queries the Docker socket for labelled containers:',
      code_lines: [
        "- job_name: 'magnolia'",
        '  docker_sd_configs:',
        '    - host: unix:///var/run/docker.sock',
        '      filters:',
        '        - name: label',
        "          values: ['prometheus-scrape=true']",
        '  relabel_configs:',
        '    - source_labels: [__meta_docker_container_label_role]',
        '      target_label: role'
      ],
      note: 'Kamal already labels every container with its role — we just reuse it. Names can churn all they like.'
    )
  end
end

class DockerSocketAccessSlide < Slide
  def slide_primitives
    code_panel_primitives(
      title: 'Detail: Reaching the Docker Socket',
      lead: 'Prometheus runs as nobody (UID 65534): mount the socket read-only and add the docker group:',
      code_lines: [
        'prometheus:',
        '  options:',
        '    volume:',
        '      - /var/run/docker.sock:/var/run/docker.sock:ro',
        '    group-add: "988"'
      ],
      note: "Find the GID with: stat -c '%g' /var/run/docker.sock — it varies by host, so never assume it."
    )
  end
end

class TargetsDebuggingSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: When Discovery Breaks',
      lead: "The Prometheus targets API reports every target's health and lastError.",
      bullets: [
        'curl 127.0.0.1:9090/api/v1/targets over an SSH tunnel',
        'lastError caught /metrics returning 302 — it was behind Devise auth',
        'And Sidekiq silent on 9394 — the new metrics server had not been deployed yet',
        'kamal app logs -r job / -r heavy to isolate one role'
      ],
      note: 'Mount metrics outside any authenticate block, or Prometheus just scrapes the login page.',
      size_px: 30
    )
  end
end

class SidekiqMetricsSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Sidekiq Metrics',
      lead: 'Puma exposes a /metrics route easily. Sidekiq processes have no web server.',
      bullets: [
        'Spawn a background Puma thread inside Sidekiq to serve Yabeda metrics on port 9394',
        'Two Sidekiq processes — general jobs, and memory-hungry Lighthouse scans (concurrency: 1)',
        'Prometheus discovers them both automatically'
      ]
    )
  end
end

class WebrickToPumaSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: From WEBrick to Puma',
      lead: 'yabeda-prometheus ships a one-line metrics server — start_metrics_server! boots WEBrick on 9394. We started there:',
      bullets: [
        'WEBrick works, but it collects the odd CVE — and its own docs say plainly it is not built for production',
        'We already run Puma for the web role, so why drag a second, weaker server into the image?',
        'PrometheusMetricsServer boots a tiny embedded Puma::Server (0–4 threads) serving the same Yabeda rack app',
        'Dropped the webrick gem entirely — one less thing shipping in production'
      ],
      note: 'Same metrics endpoint on 9394, served by the server we already trust.',
      size_px: 30
    )
  end
end

class MetricsServerCodeSlide < Slide
  def slide_primitives
    code_panel_primitives(
      title: 'Detail: The Whole Server',
      lead: 'The entire Puma-based metrics server — no framework, just the parts we need:',
      code_lines: [
        'class PrometheusMetricsServer',
        '  def self.start!(app: Yabeda::Prometheus::Exporter.rack_app,',
        '                  host: default_host, port: default_port)',
        '    server = Puma::Server.new(app, nil,',
        '                              min_threads: 0, max_threads: 4)',
        '    server.add_tcp_listener(host, port)',
        '    server.run',
        '    server',
        '  end',
        'end'
      ],
      language: :ruby,
      size_px: 22,
      note: 'Booted from the Sidekiq on(:startup) hook — the same rack app the web role mounts at /metrics.'
    )
  end
end

class AlertingAsCodeSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Alerting as Code',
      lead: "Don't stare at dashboards all day. Provision Grafana alerts as code (rules.yaml) with thresholds:",
      bullets: [
        'Target down — container/service isn\'t responding',
        'Rails error rate — 5xx ratio > 5% over 5 minutes',
        'Disk full — root filesystem > 85% utilization',
        'Sidekiq dead jobs — exhausted all retries'
      ]
    )
  end
end

class AlertRuleAnatomySlide < Slide
  def slide_primitives
    code_panel_primitives(
      title: 'Detail: Anatomy of a Rule',
      lead: 'Each rule is a Prometheus query (A) fed into a threshold (C), version-controlled in rules.yaml:',
      code_lines: [
        '- uid: mm_instance_down',
        '  title: Target down',
        '  for: 2m  # must persist 2 min',
        '  noDataState: OK  # deploys cycle containers',
        '  data:',
        '    - refId: A  # instant query: up',
        '    - refId: C  # threshold on A',
        '      conditions:',
        '        - evaluator: { type: lt, params: [1] }'
      ],
      note: 'Never edited in the UI, so there is no click-ops drift.'
    )
  end
end

class AlertQueriesDetailSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: The Queries That Page Us',
      lead: 'Thresholds are boring on purpose — the PromQL is where the judgement lives:',
      bullets: [
        'Target down — up == 0 for 2m (static node/redis/postgres targets still report it)',
        '5xx ratio — rate(5xx) / rate(all) > 5% over 5m, clamp_min to dodge divide-by-zero',
        'Disk — 1 − avail/size on / above 85%, excluding tmpfs & overlay mounts',
        'Reboot required — node_reboot_required > 0 for 15m'
      ],
      note: 'noDataState: OK on every rule, so a deploy cycling containers never pages us.',
      size_px: 30
    )
  end
end

class AlertDeliverySlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Alert Delivery',
      lead: 'App containers get a changing internal DNS name — so Grafana routes to a public webhook on Rails.',
      bullets: [
        'Authenticated via a Bearer token (GRAFANA_ALERT_TOKEN)',
        'Our Alerts::DispatchJob receives the payload',
        'Fans out dynamically via SMS and Email'
      ],
      note: 'Robust across deploys without needing stable container names.'
    )
  end
end

class WatchmenSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Who Watches the Watchmen?',
      lead: 'A bit of dogfooding: our Staging instance monitors Production — with the very product we are building.',
      bullets: [
        'Staging runs uptime checks against Production\'s public endpoint',
        'And Lighthouse scans it, exactly like any customer site',
        'If Production goes dark, the alert fires from a different box entirely'
      ],
      note: 'Never let a server be solely responsible for reporting its own death.'
    )
  end
end

class WatchmenAspirationSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: The Aspiration',
      lead: 'Uptime + Lighthouse prove Production answers the door. Next we want Staging to see inside:',
      bullets: [
        'Staging Prometheus scraping Production targets over WireGuard',
        'Deep metrics — queue depth, memory, disk — even when Production\'s own stack is down',
        'So the box reporting the death is never the box that died'
      ],
      note: 'Aspirational — the cross-scrape is not wired up yet. Today it is uptime-only.'
    )
  end
end

class ParanoiaSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Paranoia-Driven Development',
      lead: 'We run headless Chromium via Lighthouse to scan arbitrary third-party websites.',
      bullets: [
        'Tempting to pass --no-sandbox to make Chrome run in Docker',
        'A malicious site exploiting a V8/Blink bug breaks out of the renderer into your container'
      ],
      note: "Congratulations — you've just built RCE-as-a-Service."
    )
  end
end

class ThreatModelSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: Three Different Attacks',
      lead: 'One hostile URL, three distinct attacks — and no single control stops all three:',
      bullets: [
        'SSRF — no exploit needed; Chrome will fetch cloud metadata, Redis, or file:///. Stopped by egress control, not sandboxing',
        'Renderer RCE — a Chrome 0-day in V8/Blink. Stopped by removing the prize and adding a real sandbox',
        'Resource exhaustion — redirect loops and huge pages. Stopped by CPU, memory, and pid ceilings'
      ],
      note: 'The insight: match each control to its attack — there is no single silver bullet.',
      size_px: 30
    )
  end
end

class SecretlessRunnerSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: Take Away the Prize',
      lead: 'Highest-leverage move: the process that renders hostile pages holds nothing worth stealing.',
      bullets: [
        'The Lighthouse worker renders nothing — it POSTs { type, url } to a standalone browser-runner',
        'The runner is its own minimal image, not a Rails process — no master key, no DATABASE_URL',
        'Kamal accessories do not inherit env.secret — that is precisely the point',
        'Compromise the renderer and you get a box with no credentials and no route to the database'
      ],
      note: 'A Sidekiq worker cannot be secret-less — Rails needs the master key — so the renderer simply is not one.',
      size_px: 30
    )
  end
end

class SandboxBoundarySlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: Wrap the Renderer',
      lead: 'Secrets gone, we still wall the renderer off from the host kernel:',
      bullets: [
        'The browser-runner runs under gVisor (runsc) — a user-space kernel intercepting Chrome\'s syscalls',
        'cap-drop: all — the container is handed zero Linux capabilities',
        'Read-only root filesystem; only small tmpfs mounts are writable',
        'pids-limit and memory ceilings cap any runaway render'
      ],
      note: 'gVisor over Firecracker — a drop-in Docker runtime, lighter, and it won the June spike.',
      size_px: 30
    )
  end
end

class EgressLockdownSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: Control the Network',
      lead: 'SSRF needs no exploit — so the renderer only ever reaches the public internet:',
      bullets: [
        'The runner sits on its own isolated Docker bridge with a pinned IP',
        'A DOCKER-USER egress firewall confines it to public traffic — no Redis, Postgres, or metadata',
        'App-layer UrlGuard rejects bad schemes and hosts resolving to internal or link-local space',
        'The guard is the cheap early block; the firewall is the real boundary'
      ],
      note: 'Redirects and sub-resources slip past URL checks — only the network layer truly stops SSRF.',
      size_px: 30
    )
  end
end

class WireGuardSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: '2. Zero-Trust Access with WireGuard',
      lead: 'Leaving SSH on port 22 exposed invites constant brute-force scanning.',
      bullets: [
        'Closed public port 22 entirely via UFW',
        'Installed WireGuard VPN (in-kernel, minimal dependencies)',
        'Only the WireGuard UDP port is open — it silently drops unauthorized packets',
        'SSH, Grafana and Prometheus all require VPN peership'
      ]
    )
  end
end

class WireGuardBackstopSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'The WireGuard Backstop',
      lead: 'Risk: an unattended kernel upgrade breaks the wg0 module, the server reboots, and we are locked out.',
      bullets: [
        'Backstop: our provider (OVH/Hetzner) Rescue Mode / KVM console',
        'The documented break-glass method'
      ],
      note: 'Document your provider\'s rescue workflow before you drop public SSH access.'
    )
  end
end

class UnattendedSecuritySlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: '3. Unattended Security',
      lead: 'Security should be built-in from day one and require zero ongoing effort.',
      bullets: [
        'Unattended-upgrades — applies critical security patches daily',
        'Fail2ban — bans malicious IPs from any remaining public ports',
        'UFW — default deny; only 80, 443, and the WireGuard UDP port',
        'SSH hardening — PermitRootLogin no, PasswordAuthentication no'
      ],
      note: 'A kernel patch writes /var/run/reboot-required; node_exporter surfaces it and we get alerted to schedule a reboot.',
      size_px: 30
    )
  end
end

class RebootWiringDetailSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'Detail: How Reboot-Required Becomes an Alert',
      lead: 'The full chain, provisioned by Ansible.',
      bullets: [
        'unattended-upgrades writes /var/run/reboot-required after a kernel patch',
        'A systemd timer runs a small script every 15 minutes',
        'It writes node_reboot_required into the node_exporter textfile collector',
        'Prometheus scrapes it; Grafana fires after 15m of it being pending',
        'Alert → public webhook → Alerts::DispatchJob → SMS + email'
      ],
      note: 'Zero new delivery config — it rides the existing alert pipeline.',
      size_px: 30
    )
  end
end

class BackupsSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: '4. Backups and Integrity',
      lead: "A backup is meaningless if it hasn't been tested — or if it dies with your server.",
      bullets: [
        'Host backup of full disk',
        'Off-site to Cloudflare R2 — a completely different provider than our host',
        'Portability: fresh VPS, run Ansible, kamal setup, restore — in minutes',
        'Future: kamal-backup (wraps Restic) as a looped accessory — encrypted & deduplicated',
      ],
      note: 'Scheduled restore drills (kamal-backup drill local) prove this actually works.',
      size_px: 30
    )
  end
end

class ProvisioningSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: '5. Automated Server Provisioning',
      lead: 'Never configure servers manually. Manual config = configuration drift.',
      bullets: [
        'WireGuard, UFW, swap, Docker, non-root users — all in an idempotent Ansible playbook',
        'A server dies? Follow the playbok and an identical, secured box is ready for kamal setup'
      ]
    )
  end
end

class SecretsSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: '6. Secrets Management',
      lead: 'How do we eliminate the "bus factor"? (Or as we call it, the "circus factor".)',
      bullets: [
        'A company 1Password account for all infrastructure secrets',
        'DB passwords, Rails master key, Grafana credentials, SSH keys & WireGuard configs',
        "Kamal's native 1Password integration (.kamal/secrets) decouples secrets from local .env",
        'That also means if I make changes, Mala automatically gets the updates'
      ],
      note: 'If a teammate runs away to join the circus, the team still holds the keys to the castle.'
    )
  end
end

class MaintenanceCalendarSlide < Slide
  def slide_primitives
    image_bullets_primitives(
      title: 'The Maintenance Calendar (Mostly Empty)',
      image: KittenPhoto::IMAGE,
      natural_wh: KittenPhoto::NATURAL_WH,
      attribution: KittenPhoto::ATTRIBUTION,
      image_side: :right,
      frame_w: 360,
      lead: "We didn't reduce the ongoing work. We moved it off the calendar.",
      bullets: [
        'Daily: nothing scheduled — react to alerts, not a checklist',
        'Weekly: skim Grafana, check the Sidekiq dead set, confirm backups are green',
        { text: 'Monthly: the deliberate stuff',
          sub: ['Backup/Restore drill',
                'Reboot into any pending kernel patch',
                'Review/rotate the 1Password secrets',
                'Re-run Ansible to correct drift'] }
      ],
      size_px: 28
    )
  end
end

class EventQueueSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'From a Calendar to an Event Queue',
      lead: 'Every recurring chore got pushed somewhere it runs itself:',
      bullets: [
        'Into an accessory — backups, metrics, TLS renewal',
        'Into the OS — unattended-upgrades, fail2ban, UFW',
        'Into an alert — disk, 5xx, dead jobs, reboot-required',
        'Human-only: choosing when to pull the trigger on a reboot',
        'Human-only: proving a restore works — a drill, not a green checkmark'
      ],
      note: 'The one recurring manual action with no automation is the kernel-patch reboot — and that\'s on purpose.',
      size_px: 30
    )
  end
end

class KittenSlide < Slide
  def slide_primitives
    image_bullets_primitives(
      title: 'Obligatory Kitten Break',
      image: KittenPhoto::IMAGE,
      natural_wh: KittenPhoto::NATURAL_WH,
      attribution: KittenPhoto::ATTRIBUTION,
      image_side: :right,
      bullets: [
        'Every good talk needs one.',
        'This one wears yellow sunglasses.',
        'The credit in the corner is clickable — try it.'
      ]
    )
  end
end

class StillToLearnSlide < Slide
  def slide_primitives
    bullet_list_primitives(
      title: 'What We Still Need to Learn',
      lead: "Our journey isn't over. Here's what we're tackling next:",
      bullets: [
        'Multi-region scaling — routing Sidekiq jobs to remote runners over WireGuard',
        'High availability — load balancing across multiple Kamal nodes',
        'Dynamic multi-tenant SSL — swap kamal-proxy for Caddy, provisioning certs on demand for white labeling',
        '... and whatever unknown unknowns we uncover'
      ]
    )
  end
end

class DemoSlide < Slide
  def slide_primitives
    centered_primitives(
      title: "Enough slides —",
      accent: 'Demo',
      subtitle: 'Let us watch the running stack.'
    )
  end
end

class QRCodeSlide < Slide
  IMAGE = 'sprites/qr-code-1784857084800.png'.freeze
  SIZE = 440
  PAD = 24

  def slide_primitives
    x = 640 - SIZE / 2
    y = 360 - SIZE / 2 + 20
    [
      heading('Bloomlight'),
      { x: x - PAD, y: y - PAD, w: SIZE + 2 * PAD, h: SIZE + 2 * PAD, path: :solid, r: 255, g: 255, b: 255 },
      { x: x, y: y, w: SIZE, h: SIZE, path: IMAGE },
      { x: 640, y: y - PAD - 24, text: 'Scan for Bloomlight early access.', size_px: 30, anchor_x: 0.5, **MUTED }
    ]
  end
end

class QASlide < Slide
  def slide_primitives
    centered_primitives(
      title: 'Thank you!',
      accent: 'Q&A',
      subtitle: 'Any questions on Day 2 of Kamal?'
    )
  end
end
