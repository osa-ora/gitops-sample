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

```
./dev-ops-script.sh https://hooks.slack.com/....
```

Now, in order to install the ArgoCD GitOps Demo you need to install ArgoCD operator in OpenShift, and once installed, you need to provision an ArgoCD instance in the cicd namespace.

Give it a name such as argocd

Now, get the password for the admin user from the secret: argocd instance name - cluster for example: argocd-cluster

<img width="1481" alt="Screen Shot 2022-01-09 at 15 50 59" src="https://user-images.githubusercontent.com/18471537/148685061-0e4a0abd-9de4-420a-95d2-155fc6ee6e2d.png">


Click on the route and Login to ArgoCD instance using either OpenShift or admin/{password}. 
Make sure OC & Argocd commands are installed and execute the following commands:
```
oc login .....
argocd cluster list
//it will show the current cluster, we can use argocd cluster add ==> to add any new managed cluster and namespaces to this argocd instance
```
To insall our applications, execute the following commands: 

```
argocd app create maven-app-gitops --repo=https://github.com/osa-ora/gitops-sample --path=maven-app --dest-server=https://kubernetes.default.svc --dest-namespace=dev --sync-policy=auto

argocd app create dotnet-app-gitops --repo=https://github.com/osa-ora/gitops-sample --path=dotnet-app --dest-server=https://kubernetes.default.svc --dest-namespace=dev --sync-policy=auto
```

Alternatively, we can use:

```
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/maven-app-gitops.yaml
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/dotnet-app-gitops.yaml

```
Or even create it from the GUI/YAML from the Operator or ArgoCD GUI.

You'll get an error that this 'dev' namespace is not managed, to fix it, from the command line we can use the "argocd cluster add" command, or from the GUI go to the current cluster and add the 'dev' namespace.

<img width="1382" alt="Screen Shot 2022-01-13 at 09 50 46" src="https://user-images.githubusercontent.com/18471537/149287961-2b5796e1-1255-4815-9930-5eed4863dc6d.png">

Then add a role binding to the dev namespace that allows the "argocd-application-controller" service account (in cicd namespace) to manage the resources in dev namespace.

<img width="747" alt="Screen Shot 2022-01-13 at 09 53 22" src="https://user-images.githubusercontent.com/18471537/149288343-78e7fd2d-5b09-4741-a1f2-7d87170e566f.png">

Now, the argocd will be able to manage the applications in 'dev' namespace.

<img width="1787" alt="Screen Shot 2022-01-09 at 16 11 52" src="https://user-images.githubusercontent.com/18471537/148685944-bd82f8e2-a012-4e24-935e-06887016878e.png">


Try to change the replica count in the deployment.yaml file and check how it will auto-sync this into the deployed application.


<img width="1320" alt="Screen Shot 2022-01-09 at 16 24 37" src="https://user-images.githubusercontent.com/18471537/148686483-326019b4-37b0-4274-81c2-c5b3beafe694.png">


Try to change replica count, delete the deployments, services and routes and sync these applications again and see how this will be reflected.

Note: You might need to force the argocd to replace the deployment object to avoid the out of sync issue when the image name has the SHA signature, as GitOps practise, you need always to update the Git reposiotiry with your image details to be the source of truth for your applications.

Now, instead of using the default project, we can create our own project and add all our applications into it:
The project needs the source repository allowed, we can open it for any reposiotry using * and the destination which can be also opened or restricted to specific destination:

```
argocd proj create apps -s https://github.com/osa-ora/gitops-sample -d https://kubernetes.default.svc,dev
argocd app set maven-app-gitops --project apps 
argocd app set dotnet-app-gitops --project apps

```

<img width="986" alt="Screen Shot 2022-01-13 at 10 45 01" src="https://user-images.githubusercontent.com/18471537/149296220-bebdb38a-854f-4a86-b21b-656825a9f03f.png">
