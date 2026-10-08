# CoreDNS

CoreDNS is a pluggable DNS server used by Kubernetes to provide Service discovery. Its Kubernetes plugin watches API objects and serves cluster names; external queries are forwarded to configured upstream resolvers. It allows applications to use stable names even when Pod IPs change.

A typical Pod uses ClusterFirst DNS policy. Its resolver sends cluster queries to the kube-dns Service (the Service name is retained even when the implementation is CoreDNS). CoreDNS resolves `<service>.<namespace>.svc.cluster.local`; a normal Service returns its ClusterIP and a headless Service returns endpoints. Non-cluster queries flow through the `forward` plugin and results may be cached.

Configuration lives in the kube-system `coredns` ConfigMap as a Corefile. Common plugins include `errors`, `health`, `ready`, `kubernetes`, `prometheus`, `forward`, `cache`, `loop`, `reload` and `loadbalance`. The actual Corefile and logs from this cluster are captured in [the transcript](../evidence/run.txt); no speculative configuration is presented as live state.

```powershell
kubectl --context devops-homework -n kube-system get pods -l k8s-app=kube-dns
kubectl --context devops-homework -n kube-system get svc kube-dns
kubectl --context devops-homework -n kube-system get configmap coredns -o yaml
kubectl --context devops-homework -n kube-system logs deployment/coredns --tail=50
kubectl --context devops-homework -n hw11 exec dns-client -- cat /etc/resolv.conf
kubectl --context devops-homework -n hw11 exec dns-client -- nslookup kubernetes.default.svc.cluster.local
```

Troubleshoot one layer at a time: correct name/namespace, Service existence, Pod DNS policy/search list, kube-dns endpoints, CoreDNS health/logs, UDP and TCP port 53 policy, upstream resolver reachability. Compare DNS queries with direct-IP application access. Session 14 safely reproduces a Pod with a wrong resolver without altering global CoreDNS.

Reference: [CoreDNS Service discovery](https://kubernetes.io/docs/tasks/administer-cluster/coredns/).
