# Pixelcloud nginx-proxy

This docker-based service uses [nginx-proxy](https://github.com/nginxproxy/nginx-proxy), [docker-gen](https://github.com/nginxproxy/docker-gen) and [acme-companion](https://github.com/nginx-proxy/acme-companion/tree/main/docs).

## Description

Based on nginx-proxy, this service uses nginx (modified with config inspired from mozilla's boilerplate) and monitors other docker services having ``VIRTUAL_HOST`` environment variable to automatically proxy them.

Moreover, if said services also have ``LETSENCRYPT_HOST`` variable, it will automatically generate a Let's Encrypt SSL certificate, provided the requirements are met.

## Usage

### Environment Variables

#### Ports

You should create a ``.env`` file, located in nginx-proxy's directory root and declare the necessary variables needed in ``docker-compose.yml``

Production example:

```
HTTP_PORT=80
HTTPS_PORT=443
DEFAULT_EMAIL=my@email.com
DEBUG=0
```

Development example:

```
HTTP_PORT=8080:80
HTTPS_PORT=8443:443
DEFAULT_EMAIL=my@email.com
DEBUG=1
ACME_CA_URI=https://acme-staging-v02.api.letsencrypt.org/directory

```

#### no-www

If the variable ``WWW`` is set to ``no-www`` inside your proxied service, nginx-proxy will automatically create a www.domain.com to domain.com redirection. You should add www.domain.com to ``LETSENCRYPT_HOST`` variable to get an SSL certificate as well.

## Testing

Once you have everything running, you can quickly check if everything works as intended, by creating a ``docker-compose.yml`` file in another directory with the following content:


```yaml
version: '3'

services:
  iamzob:
    image: jwilder/whoami
    container_name: site-whoami-http
    environment:
      - VIRTUAL_HOST=mydomain.com
      - VIRTUAL_PORT=8000
      - LETSENCRYPT_HOST=mydomain.com
      - WWW='no-ww'
    networks:
      - proxy-tier

networks:
  proxy-tier:
    name: nginx-proxy
    external: true
```

Don't forget to replace ``mydomain.com`` with your actual domain/subdomain. You can then run ``docker compose up`` or ``docker-compose up`` and check the logs from nginx-proxy.

If everything worked, you should see some certificate files in the ``volumes/nginx/certs/`` folder. Please note that if you're running the staging ``ACME_CA_URI``, then the certificate won't be symlinked and therefore won't be loaded by docker-gen.

After you've checked that certifiate generation works on staging, you can stop the nginx-proxy services, modify the ``.env`` file and comment the ``ACME_CA_URI`` line, which will switch to production CA.

