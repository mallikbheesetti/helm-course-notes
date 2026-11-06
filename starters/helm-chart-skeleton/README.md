# Chart Skeleton

Copy this directory to start a lab:

```bash
cp -r starters/helm-chart-skeleton ~/helm-labs/mychart
cd ~/helm-labs/mychart
```

Before using it:

1. Change `name` in `Chart.yaml`.
2. Rename the helper prefixes in `templates/_helpers.tpl` from
   `chart-skeleton` to your chart name.
3. Adjust `values.yaml`.
4. Run:

   ```bash
   helm lint .
   helm template demo .
   helm install demo . -n demo --create-namespace
   ```

The skeleton includes:

- A Deployment and Service with configurable image, replicas, and port
- An optional Ingress using `networking.k8s.io/v1`
- Shared name, fullname, labels, and selector helpers
- A `NOTES.txt` with access instructions
