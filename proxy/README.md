# Embloy-Core-Server Integration Proxy

The proxy module is designed as a simple proxy and cache node for Embloy Quicklink.
It can be used to integrate Embloy without using a Server-SDK or embedding any code on a third party site, allowing the third party to simple direct to a generic URL which then proxies the Quicklink request by fetching a Request and Client token remotely. The architecture might look like this:

```
                                                  ┌─────────┐
┌───────────────────────┐                     ┌─► │ Proxy 1 ├──┐  ┌────────┐
│                       ├─────────────────────┘   └─────────┘  └─►│        │/sdk/request/auth/token
│  Third party service  │GET apply.embloy.com                     │ GO SDK │         ┌──────────┐
│   (DNS-RR/HTTP 302)   │GET apply.embloy.com                     │        │────────►│ Core-API │
│                       ├─────────────────────┐   ┌─────────┐  ┌─►└────────┘         └──────────┘
└───────────────────────┘                     └─► │ Proxy 2 ├──┘
                                                  └─────────┘
```

## Configuration

The following configuration options are available via environment variables:

- `ADMIN_TOKEN`: Can be used to authenticate for client tokens. No default value set.
- `MAIN_INSTANCE`: The url of the main Embloy website. Used to redirect user. No default value set.
- `GIN_MODE`: The mode in which Gin runs. Can be `debug`, `release`, or `test`. Defaults to `debug`.
- `LOG_DIR`: The directory where logs are stored. Defaults to `var/log/embloy-proxy`.
- `LOG_LEVEL`: The level of logging. Can be `debug`, `info`, `warn`, `error`, `fatal`, or `panic`. Defaults to `info`.

## Run

To start the proxy service, simply run:

```sh
go run cmd/proxy/proxy.go
```
