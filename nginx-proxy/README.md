# Pixelcloud nginx-proxy

This docker-based service uses [nginx-proxy](https://github.com/nginxproxy/nginx-proxy), [docker-gen](https://github.com/nginxproxy/docker-gen) and [acme-companion](https://github.com/nginx-proxy/acme-companion/tree/main/docs).

## Description

Based on nginx-proxy, this service uses nginx (modified with config inspired from mozilla's boilerplate) and monitors other docker services having ``VIRTUAL_HOST`` environment variable to automatically proxy them.

Moreover, if said services also have ``LETSENCRYPT_HOST`` variable, it will automatically generate a Let's Encrypt SSL certificate, provided the requirements are met.

Please keep in mind that this project has VERY opinionated default settings as it's part of a larger whole. This repo is public to be used for educational purposes.

## Usage

### Environment Variables

#### Ports

You should create a ``.env`` file, located in nginx-proxy's directory root and declare the necessary variables needed in ``docker-compose.yml``

Production example:

```
HTTP_PORT=80
HTTPS_PORT=443
DEFAULT_EMAIL=my@email.com
ENABLE_IPV6=true
```

Development example:

```
HTTP_PORT=8080
HTTPS_PORT=8443
DEFAULT_EMAIL=my@email.com
DEBUG=1
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory
```

#### no-www

If the variable ``WWW`` is set to ``no-www`` inside your proxied service, nginx-proxy will automatically create a www.mydomain.com to mydomain.com redirection. You should add www.domain.com to ``LETSENCRYPT_HOST`` variable to get an SSL certificate as well.

## Networks

2 external networks need to be created (one being optional if you don't plan to support IPv6 without docker's userland-proxy).

## nginx-proxy network

It's a simple external bridged network that can be created by running ``docker network create nginx-proxy`` on the host.

## edge network

This is an IPv6 enabled network that can be removed from ``docker-compose.yml`` (both from the nginx service's network list and from the networks list at the end of the file). You should also remove ``ENABLE_IPV6: true`` from the docker-gen bloc.
If you want to really support IPv6 (without the IPv6 to IPv4 userland proxy) to retrieve the real IPv6 IPs from users, you should first enable IPv6 in dockerd's ``daemon.json``. [This guide](https://medium.com/@skleeschulte/how-to-enable-ipv6) (or [this one](https://dev.to/joeneville_/build-a-docker-ipv6-network-dfj) if you plan on using swarm) details the steps required.

Once you have ipv6 enabled on the default docker bridge network, you can create the edge network by running ``docker network create --ipv6 --subnet fd00:dead:beef::/48 edge``

You might need to run ``sudo ip6tables -t nat -A POSTROUTING -s fd00:dead:beef::/48 ! -o docker0 -j MASQUERADE`` (note that this is not reboot-proof).

Finally, you will need to enable some sort of IPv6 NAT. You can use [this repo](https://github.com/robbertkl/docker-ipv6nat) quickly: ``docker run -d --restart=always -v /var/run/docker.sock:/var/run/docker.sock:ro --cap-drop=ALL --cap-add=NET_RAW --cap-add=NET_ADMIN --cap-add=SYS_MODULE --net=host --name ipv6nat robbertkl/ipv6nat``, and it will take care of everything (don't forget to make it reboot-proof).

You can also use Docker's official (and experimental) ``ip6tables`` support, by enabling it in dockerd's ``daemon.json``. Don't forget to also enable the ``experimental`` flag.


Depending on your use-case, you may also want to disable Docker's userland-proxy by adding ``"userland-proxy": false`` to your ``daemon.json`` file.

Your ``daemon.json`` should look something like this:

```json
{
  "experimental": true,
  "ipv6": true,
  "ip6tables": true,
  "fixed-cidr-v6": "fd00::/80"
}
```

Remember that any modification of this file should be followed by restarting the Docker service, not just reloading.

## Testing

Once you have everything running, you can quickly check if everything works as intended, by creating a ``docker-compose.yml`` file in another directory with the following content:


```yaml
version: '3'

services:
  whoami:
    image: jwilder/whoami
    container_name: site-whoami-http
    environment:
      - VIRTUAL_HOST=mydomain.com
      - VIRTUAL_PORT=8000
      - LETSENCRYPT_HOST=mydomain.com
      - WWW='no-ww'

networks:
  default:
    name: nginx-proxy
    external: true
```

Don't forget to replace ``mydomain.com`` with your actual domain/subdomain. You can then run ``docker compose up`` or ``docker-compose up`` and check the logs from nginx-proxy.

Note that this example is not meant to test IPv6 connectivity.

If everything worked, you should see some certificate files in the ``volumes/nginx/certs/`` folder.

After you've checked that certifiate generation works on staging, you can stop the nginx-proxy services, modify the ``.env`` file and comment the ``ACME_CA_URI`` line, which will switch to production CA.

