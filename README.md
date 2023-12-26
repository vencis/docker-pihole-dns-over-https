<!-- markdownlint-configure-file { "MD004": { "style": "consistent" } } -->
<!-- markdownlint-disable MD033 -->


# Pi-hole with DNS over HTTPS (DoH) using Docker

<div style="display: flex; align-items: center; justify-content: center;">
    <img src="https://pi-hole.github.io/graphics/Vortex/Vortex_Vertical_wordmark_lightmode.png" alt="Image" height="200">
    <p style="font-size: 100px;margin-right: 20px;">+</p>
    <p style="font-size: 40px;">DNS over <br/>HTTPS (DoH) <br/> via <strong>Cloudflared</strong></p>
</div>

<!-- markdownlint-enable MD033 -->

## Introduction
This project provides a lightweight Docker setup for [Pi-hole](https://github.com/pi-hole/pi-hole) with DNS over HTTPS support via [Cloudflared](https://github.com/cloudflare/cloudflared). It supports both x86, AMD64, and ARM architectures and is based on [Pi-hole's DNS over HTTPS documentation](https://docs.pi-hole.net/guides/dns/cloudflared/).

1) Install docker for your [x86-64 system](https://www.docker.com/community-edition) or [ARM system](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/). [Docker-compose](https://docs.docker.com/compose/install/) is also recommended.
2) Use the above quick start example, customize if desired.
3) Enjoy!

## Quick Start

1. Copy docker-compose.yml.example to docker-compose.yml and update as needed. See example below:
[Docker-compose](https://docs.docker.com/compose/install/) example:

```yaml
version: "3"

# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole-dns-over-https
    image: bariscimen/pihole-dns-over-https:latest
    # For DHCP it is recommended to remove these ports and instead add: network_mode: "host"
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
      - "80:80/tcp"
    environment:
      TZ: 'America/Chicago'
      # WEBPASSWORD: 'set a secure password here or it will be random'
      # DOH_DNS1: 'https://8.8.8.8/dns-query' # Uncomment to use Google DNS over HTTPS instead of Cloudflare
      # DOH_DNS2: 'https://8.8.4.4/dns-query' # Uncomment to use Google DNS over HTTPS instead of Cloudflare
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
    restart: unless-stopped
```
2. Run `docker compose up -d` to build and start pi-hole (Syntax may be `docker-compose` on older systems)
3. Once Pi-hole is running, you can access the web UI at `http://localhost/admin`. From there, you can change settings, view stats, and more.


## Configuration

The `docker-compose.yml` file contains customizable environment variables:

- `DOH_DNS1` and `DOH_DNS2`: Specify DNS over HTTPS servers. Cloudflare's servers are set by default, but you can switch to any other servers.
- Utilize other [environmental variables from the Docker Pi-Hole project](https://github.com/pi-hole/docker-pi-hole?tab=readme-ov-file#environment-variables) as needed.

## Useful Links

- [Pi-hole Documentation](https://docs.pi-hole.net)
- [Pi-hole GitHub Repository](https://github.com/pi-hole/pi-hole)
- [Cloudflared GitHub Repository](https://github.com/cloudflare/cloudflared)
- [Pi-hole's Cloudflared Setup Guide](https://docs.pi-hole.net/guides/dns/cloudflared/)

## Troubleshooting

If you encounter issues related to Docker, report them on the [GitHub project](https://github.com/bariscimen/docker-pihole-dns-over-https). For Pi-hole or general Docker queries, visit our [user forums](https://discourse.pi-hole.net/c/bugs-problems-issues/docker/30).

## Contributing

Contributions are encouraged! Please create issues for bugs or suggest enhancements. To contribute code, submit a pull request.

## License

This project is licensed under the GNU GPLv3 License.