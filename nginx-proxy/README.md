# Pixelcloud nginx-proxy

This docker-based service uses [nginx-proxy](https://github.com/jwilder/nginx-proxy), [docker-gen](https://github.com/jwilder/docker-gen) and [docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion).

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
```

Development example:

```
HTTP_PORT=8080:80
HTTPS_PORT=8443:443
ACME_CA_URI=https://acme-staging.api.letsencrypt.org/directory
```

#### no-www

If the variable ``WWW`` is set to ``no-www`` inside your proxied service, nginx-proxy will automatically create a www.domain.com to domain.com redirection. You should add www.domain.com to ``LETSENCRYPT_HOST`` variable to get an SSL certificate as well.
