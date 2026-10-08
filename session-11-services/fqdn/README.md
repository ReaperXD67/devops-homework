# FQDN and Kubernetes DNS

A fully qualified domain name identifies a name through the complete DNS hierarchy; a trailing dot explicitly denotes the root, for example `clusterip.hw11.svc.cluster.local.`. Kubernetes normally configures a search list that lets clients omit suffixes.

The standard Service pattern is `<service>.<namespace>.svc.<cluster-domain>`. Here the cluster domain is `cluster.local`, so `clusterip.hw11.svc.cluster.local` refers unambiguously to Service clusterip in hw11. From hw11 a client can use `clusterip`; from hw12 it can use `clusterip.hw11` or the full name. A same-named Service in another namespace is a separate object.

```powershell
kubectl --context devops-homework -n hw11 exec dns-client -- cat /etc/resolv.conf
kubectl --context devops-homework -n hw11 exec dns-client -- nslookup clusterip.hw11.svc.cluster.local
kubectl --context devops-homework -n hw11 exec dns-client -- wget -qO- http://clusterip
```

A normal ClusterIP Service resolves to a stable virtual IP. Headless Services return eligible endpoint addresses directly. StatefulSet Pod DNS commonly follows `<pod>.<headless-service>.<namespace>.svc.cluster.local` when hostname/subdomain are configured. Pod IP-based DNS records depend on DNS implementation/configuration and are not a replacement for a stable Service contract. ExternalName returns a CNAME.

Pod-to-Service flow: application resolver applies search suffixes → CoreDNS answers Service record → client opens the requested port → cluster network routes to a ready endpoint. The DNS record does not prove that the port or application is healthy. See actual lookup results in [the session transcript](../evidence/run.txt).

Reference: [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).
