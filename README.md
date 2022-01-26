# Building GitOps Sample Applications using ArgoCD

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
- dev & cicd project to use

```
./dev-ops-script.sh dev cicd https://hooks.slack.com/....
```

Now, in order to install the ArgoCD GitOps Demo you need to install ArgoCD operator in OpenShift i.e. OpenShift GitOps Operator

<img width="280" alt="Screen Shot 2022-01-26 at 09 14 59" src="https://user-images.githubusercontent.com/18471537/151119303-f8258a3e-65ab-4edb-9a48-b86a1e3243c9.png">


Once installed, you need to provision an ArgoCD instance in the cicd namespace:

<img width="1471" alt="Screen Shot 2022-01-26 at 09 16 23" src="https://user-images.githubusercontent.com/18471537/151119489-5c00c4e6-dc6b-4bb7-b0ae-73039902785c.png">

Give it a name such as "argocd"

Now, get the password for the admin user from the secret: argocd instance name - cluster for example: argocd-cluster

<img width="1481" alt="Screen Shot 2022-01-09 at 15 50 59" src="https://user-images.githubusercontent.com/18471537/148685061-0e4a0abd-9de4-420a-95d2-155fc6ee6e2d.png">


Click on the route and Login to ArgoCD instance using either OpenShift or admin/{password}. 

Make sure OC & Argocd commands are installed and execute the following commands:
```
//login to OpenShift cluster
oc login .....
//List all argocd managed clusters
argocd cluster list
//it will show the current cluster, we can use argocd cluster add ==> to add any new managed cluster and namespaces to this argocd instance
//for example: argocd cluster add $(oc config current-context) --name=argocd-managed --in-cluster --system-namespace=cicd --namespace=dev
//label the dev namespace to be managed by argocd
oc label namespace dev argocd.argoproj.io/managed-by=openshift-gitops
//Add role binding to the user argocd-argocd-application-controller so argocd can manage the dev namespace
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/role-binding-for-dev.yaml
```
Now, install our argocd applications by executing the following commands: 

```
argocd app create maven-app-gitops --repo=https://github.com/osa-ora/gitops-sample --path=maven-app --dest-server=https://kubernetes.default.svc --dest-namespace=dev --sync-policy=auto

argocd app create dotnet-app-gitops --repo=https://github.com/osa-ora/gitops-sample --path=dotnet-app --dest-server=https://kubernetes.default.svc --dest-namespace=dev --sync-policy=auto
```

Alternatively, we can use:

```
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/maven-app-gitops.yaml -n cicd
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/dotnet-app-gitops.yaml -n cicd

```
Or even you can create them from the GUI/YAML from either the Operator or ArgoCD GUI.


<img width="1787" alt="Screen Shot 2022-01-09 at 16 11 52" src="https://user-images.githubusercontent.com/18471537/148685944-bd82f8e2-a012-4e24-935e-06887016878e.png">


Try to change the replica count in the deployment.yaml file or delete some resources like deployment/service/route and check how it will auto or manaullay synched this into the deployed application.


<img width="1320" alt="Screen Shot 2022-01-09 at 16 24 37" src="https://user-images.githubusercontent.com/18471537/148686483-326019b4-37b0-4274-81c2-c5b3beafe694.png">


Note: You might need to force the argocd to replace the deployment object to avoid the out of sync issue when the image name has the SHA signature, as GitOps practise, you need always to update the Git reposiotiry with your image details to be the source of truth for your applications.

Now, instead of using the default project, we can create our own project and add all our applications into it:
The project needs the source repository allowed, we can open it for any reposiotry using * and the destination which can be also opened or restricted to specific destination:

```
argocd proj create apps -s https://github.com/osa-ora/gitops-sample -d https://kubernetes.default.svc,dev
argocd app set maven-app-gitops --project apps 
argocd app set dotnet-app-gitops --project apps

//list projects and applications using argocd command
argocd proj list
argocd proj get apps
argocd app list
argocd app get dotnet-app-gitops
argocd app get maven-app-gitops
//or sync apps from command line
argocd app sync maven-app-gitops
argocd app sync dotnet-app-gitops
```

<img width="986" alt="Screen Shot 2022-01-13 at 10 45 01" src="https://user-images.githubusercontent.com/18471537/149296220-bebdb38a-854f-4a86-b21b-656825a9f03f.png">
