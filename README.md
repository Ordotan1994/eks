# EKS Monitoring & Autoscaling Demo

## Structure

| Path | Contents |
|------|----------|
| `modules/network` | VPC, subnets, IGW, NAT, tags |
| `modules/eks` | EKS cluster & node group |
| `modules/lb_controller` | AWS Load Balancer Controller (IRSA + Helm) |
| `modules/autoscaler` | Cluster Autoscaler (IRSA + Helm) |
| `modules/monitoring` | kube‑prometheus‑stack + dashboards |
| `modules/argocd` | Argo CD (Helm) |
| `apps/hello-nginx` | NGINX Deployment, Service, HPA |
| `apps/hello-nginx-app.yaml` | Argo CD Application CR |

## Deployment

```bash
git clone https://github.com/<your-org>/<repo>.git
cd <repo>
terraform init
terraform apply             # ~15 min
