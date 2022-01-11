# gitops-sample

This is a sample GitOps project where you can use ArgoCD to synch and apply all Git repository configuration and operations into OpenShift/Kubernetes cluster.

Note: You need to install the applications and pipelines using the script "dev-ops-script.sh" in the setup-demo folder. 
This demo will install the following tools:
- Dev & CICD OpenShift projects
- Jenkins instance
- SonarQube instance
- Gitea Template
- Nexus Repository instance
- Two Tekton pipelines
- Execute both Tekton pipelines

It requires the following:
- Login to OpenShift cluster usng oc login command
- OpenShift with Tekton Pipeline installed
- OC and tkn command installed.
- Slack channel webhook URL as a parameter to send the notification into this channel

Now, in order to install the ArgoCD GitOps Demo you need to install ArgoCD operator in OpenShift, and once installed, you need to provision an ArgoCD instance. 
Give it a name such as argocd-sample 
In Dex section, Enable OpenShift OAuth.  

<img width="837" alt="Screen Shot 2022-01-10 at 09 27 37" src="https://user-images.githubusercontent.com/18471537/148730783-ecac6590-ce5e-44a1-98a3-3d3e015346fa.png">

In RBAC section, add the following policy:
```
g, systems:cluster-admins, role:admin
```

Now, you can login using OpenShift or get the password for the admin user from the secret: argocd instance name - cluster for example: argocd-sample-cluster

<img width="1481" alt="Screen Shot 2022-01-09 at 15 50 59" src="https://user-images.githubusercontent.com/18471537/148685061-0e4a0abd-9de4-420a-95d2-155fc6ee6e2d.png">


Click on the route and Login to ArgoCD instance using either OpenShift or admin/{password}. 

Create new application and configure it as following: either from GUI or from the Operator. 


```
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/maven-app-gitops.yaml
```

<img width="1787" alt="Screen Shot 2022-01-09 at 16 11 52" src="https://user-images.githubusercontent.com/18471537/148685944-bd82f8e2-a012-4e24-935e-06887016878e.png">


Try to change the replica count in the deployment.yaml file and check how it will auto-sync this into the deployed application.


Create Dotnet sample application GitOps configurations as well

```
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/dotnet-app-gitops.yaml

```

<img width="1320" alt="Screen Shot 2022-01-09 at 16 24 37" src="https://user-images.githubusercontent.com/18471537/148686483-326019b4-37b0-4274-81c2-c5b3beafe694.png">


Try to change replica count, delete the deployments, services and routes and sync these applications again and see how this will be reflected.



