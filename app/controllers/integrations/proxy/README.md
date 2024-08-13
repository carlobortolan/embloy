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

- `PORT`: The port on which the edge node should listen for incoming connections (default: 8080).
- `MAIN_INSTANCE`: The url of the Core-API instance is available. Used for public key exchange. Defaults to `https://api.embloy.com`
- `ADMIN_TOKEN`: Can be used to authenticate for client tokens. No default value set.
