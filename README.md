# gitops-sample

This is a sample GitOps project where you can use ArgoCD to synch and apply all Git repository configuration and operations into OpenShift/Kubernetes cluster.

To run this demo you need to provision ArgoCD operator, once installed, you need to install ArgoCD instance. 
Give it a name such as argocd-sample 
In RBAC section, add the following policy:
```
g, systems:cluster-admins, role:admin
```

Get the password for the admin user from the secret: argocd instance name - cluster for example: argocd-sample-cluster

<img width="1481" alt="Screen Shot 2022-01-09 at 15 50 59" src="https://user-images.githubusercontent.com/18471537/148685061-0e4a0abd-9de4-420a-95d2-155fc6ee6e2d.png">


Click on the route and Login to ArgoCD instance using admin/{password}. 

Create new application and configure it as following: either from GUI or from the Operator. 

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: maven-app-gitops
  namespace: dev
spec:
  destination:
    namespace: dev
    server: 'https://kubernetes.default.svc'
  project: default
  source:
    path: maven-app
    repoURL: 'https://github.com/osa-ora/gitops-sample'
    targetRevision: main
  syncPolicy:
    automated: {}
```

<img width="1657" alt="Screen Shot 2022-01-09 at 16 00 22" src="https://user-images.githubusercontent.com/18471537/148685410-da06acc3-fe2e-40a6-82ee-c9e0300ba61b.png">


Try to change the replica count in the deployment.yaml file and check how it will auto-sync this into the deployed application.


