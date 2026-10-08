# Kubernetes volumes

| Concept | Lifetime and responsibility | Lab/example |
|---|---|---|
| emptyDir | Created for a Pod; survives a container restart but disappears with the Pod | `/scratch` in volume-demo; temporary/cache/shared intra-Pod files |
| hostPath | Mounts a specific path on the node; node-local and security-sensitive | hostpath.yaml uses only `/tmp/devops-homework-storage`, never system directories |
| PersistentVolume (PV) | Cluster-scoped storage resource with capacity/access modes/reclaim policy | Provisioned PV appears in `kubectl get pv` |
| PersistentVolumeClaim (PVC) | Namespaced request for capacity/access modes | demo-data requests 64Mi ReadWriteOnce |
| StorageClass | Describes provisioner and storage parameters/default policy | `kubectl get storageclasses` shows Minikube default |
| Dynamic provisioning | Provisioner creates backing storage/PV when a matching PVC needs it | Default StorageClass provisions demo-data without hand-writing a PV |

[`../volumes.yaml`](../volumes.yaml) mounts a PVC at `/data` and emptyDir at `/scratch`. The script writes a separate sentinel to `/data/sentinel.txt`, deletes the Pod, reapplies it and reads the old sentinel. The startup command does not recreate that sentinel, so its survival is real persistence evidence. The emptyDir has a new lifecycle on replacement. Minikube's local storage is educational single-node storage, not durable cloud storage; deleting the cluster can remove it.

```powershell
kubectl --context devops-homework apply -f ../volumes.yaml
kubectl --context devops-homework -n hw13 get pvc
kubectl --context devops-homework get pv,storageclasses
kubectl --context devops-homework -n hw13 describe pvc demo-data
```

Binding connects a claim to a volume. Access modes and capacity must match. ReadWriteOnce permits read-write mounting from one node; ReadWriteMany support depends on the driver. The reclaim policy determines what happens to backing storage after the claim is deleted: Delete commonly removes provisioned storage, Retain leaves manual recovery/cleanup. Do not use hostPath for portable multi-node application persistence; CSI-backed volumes are generally more suitable.

References: [volumes](https://kubernetes.io/docs/concepts/storage/volumes/), [persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/), [StorageClasses](https://kubernetes.io/docs/concepts/storage/storage-classes/).

Cleanup of namespace hw13 deletes the PVC and its dynamically provisioned Delete-policy PV. The hostPath demo file belongs to the Minikube node filesystem and is not removed by namespace deletion; it remains at `/tmp/devops-homework-storage/proof.txt` until that node is cleaned up.
