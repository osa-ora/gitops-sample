# Building GitOps Sample Applications using ArgoCD

This is a sample GitOps project where you can use ArgoCD to synch and apply all Git repository configuration and operations into OpenShift/Kubernetes cluster.

<img width="634" alt="Screen Shot 2022-01-27 at 20 50 19" src="https://user-images.githubusercontent.com/18471537/151424352-ced4527c-477e-493d-a183-50c2c9df1e4a.png">

Git is always the source of truth on what happens in the system. Deployments, tests, and rollbacks always controlled through Git flow and no manual deployments/changes. If you need to make a change, you need to make a Git operation such as commit, or raise a pull request.
The golden rule for any change "If it’s not in Git, it’s not real", and this change will be reverted by the GitOps tools.


Note: You need to install the applications and pipelines using the script "dev-ops-gitops-script.sh" in the setup-demo folder. 
This demo will install the following tools:
- Dev & CICD OpenShift projects
- SonarQube instance for static code analysis
- Two Tekton pipelines for Java SpringBoot & DotNet Core Application
- Execute both Tekton pipelines

It requires the following:
- Login to OpenShift cluster usng oc login command
- OpenShift with Tekton Pipeline installed
- OC and tkn command installed.
- Slack channel webhook URL as a parameter to send the notification into this channel
- dev & cicd project names as input parameters

```
//login to OpenShift cluster
oc login ...
//download the script
curl https://raw.githubusercontent.com/osa-ora/gitops-sample/main/setup-demo/dev-ops-gitops-script.sh > dev-ops-gitops-script.sh
chmod 777 dev-ops-gitops-script.sh
//execute the script with 3 parameters: the name of "dev" project, "cicd" project and slack channel webhook url
./dev-ops-gitops-script.sh dev cicd https://hooks.slack.co...{fill in your slack url here}
```

The pipelines will do the following: 
- Git the code from the GitHub repository
- Send slack message "Started"
- Build the application
- Run the unit testing
- Run static code analysis (you need to configure the pipeline parameters against sonarqube project)
- Package the application
- Deploy it using s2i into the "dev" namespace (could be replaced by binary deployment instead)
- Expose a route to the application
- Run smoke testing (can be enriched to execute more test cases)
- Send slack message "Completed"

The pipeline accept many parameters to control the behaviour and switch on/off different steps e.g. run sonar qube or not.  

Once the pipeline execution finished, you will have both applications "maven-app" and "dotnet-app" deployed in the "dev" namespace.

<img width="1484" alt="Screen Shot 2022-01-27 at 20 44 56" src="https://user-images.githubusercontent.com/18471537/151423570-744a41ec-de9d-4381-b726-00ca93d47046.png">

You can click on the route and access both applications (note: test the maven-app by accessing the url: ${route_url}/loyalty/v1/balance/123 )

<img width="664" alt="Screen Shot 2022-01-27 at 20 46 25" src="https://user-images.githubusercontent.com/18471537/151423785-c7de8dc8-c5e2-4381-81ab-378d9f1b33c0.png">


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
//it will show the current cluster

//we can use argocd cluster add ==> to add any new managed cluster and namespaces to this argocd instance for example: 
argocd cluster add $(oc config current-context) --name=in-cluster --in-cluster --system-namespace=cicd --namespace=dev
```
```
//label the dev namespace to be managed by argocd
oc label namespace dev argocd.argoproj.io/managed-by=openshift-gitops

//Add role binding to the user argocd-argocd-application-controller so argocd can manage the dev namespace
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/role-binding-for-dev.yaml

//Note: you may need to delete one of the in-cluster from the GUI and add the namespace dev to the remaining one so the output looks like:
argocd cluster list                                                                                           
SERVER                                         NAME        VERSION  STATUS      MESSAGE  PROJECT
https://kubernetes.default.svc (2 namespaces)  in-cluster  1.21     Successful
```
Now, install our argocd applications by executing the following commands: 

```
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/maven-app-gitops.yaml -n cicd
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/dotnet-app-gitops.yaml -n cicd

```

Alternatively, we can use:
```
argocd app create maven-app-gitops --repo=https://github.com/osa-ora/gitops-sample --path=maven-app --dest-server=https://kubernetes.default.svc --dest-namespace=dev --sync-policy=auto

argocd app create dotnet-app-gitops --repo=https://github.com/osa-ora/gitops-sample --path=dotnet-app --dest-server=https://kubernetes.default.svc --dest-namespace=dev --sync-policy=auto
```

Or even you can create them from the GUI/YAML from either the Operator or ArgoCD GUI and supply the required parameters.


<img width="1787" alt="Screen Shot 2022-01-09 at 16 11 52" src="https://user-images.githubusercontent.com/18471537/148685944-bd82f8e2-a012-4e24-935e-06887016878e.png">

Try to change the replica count in the deployment.yaml file or delete some resources like deployment/service/route and check how it will auto or manaullay synched this into the deployed application.

<img width="1320" alt="Screen Shot 2022-01-09 at 16 24 37" src="https://user-images.githubusercontent.com/18471537/148686483-326019b4-37b0-4274-81c2-c5b3beafe694.png">


Note: You might need to force the argocd to replace the deployment object to avoid the out of sync issue when the image name has the SHA signature, as GitOps practise, you need always to update the Git respository with your container image details to be the source of truth for your applications. Also the pipeline should tag the container image with specific tag.  

Now, instead of using the default argocd project, we can create our own project and add all our applications into it:
The project needs the following information:   
1) Define the allowed source repositories, we can open it for any reposiotry using *   
2) The destination cluster/namespaces which can be also opened or restricted to specific destination. 

In the following application, we just allowed this github repository and the dev namespace as destination:  

```
argocd proj create apps -s https://github.com/osa-ora/gitops-sample -d https://kubernetes.default.svc,dev
argocd app set maven-app-gitops --project apps 
argocd app set dotnet-app-gitops --project apps
```
```
//Some argocd commands
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

You can also install the 3rd example which is the sample serverless demo by the executing the following command:
```
oc apply -f https://raw.githubusercontent.com/osa-ora/gitops-sample/main/argocd/serverless-maven-app-gitops.yaml -n cicd
```


