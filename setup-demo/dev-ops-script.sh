#!/bin/sh
if [ "$#" -ne 1 ];  then
  echo "Usage: $0 slack_url" >&2
  exit 1
fi

echo "Please Login to OCP using oc login ..... "  
echo "Make sure Openshift Pipeline Operator is installed"
echo "Make sure oc and tkn commands are installed"
echo "Slack url: $1"
echo "Press [Enter] key to resume..." 
read

echo “Create Required Projects …”  
oc new-project dev 
oc new-project cicd

echo “Create Jenkins …”  
oc new-app jenkins-persistent  -p MEMORY_LIMIT=2Gi  -p VOLUME_CAPACITY=4Gi -n cicd
oc policy add-role-to-user edit system:serviceaccount:cicd:default -n dev
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n dev

echo “Create SonarQube …”  
oc process -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/sonarqube-persistent-template.yaml | oc create -f -

echo “Create Nexus …”  
oc new-app sonatype/nexus -n cicd
echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: nexus-pvc
spec:
 accessModes:
 - ReadWriteOnce
 resources:
   requests:
     storage: 4Gi" | oc create -f -
oc set volumes deployments/nexus
oc scale deployments/nexus --replicas=0 -n cicd
oc set volumes deployments/nexus --remove --name=nexus-volume-1 
oc set volumes deployments/nexus --add --name=nexus-data --mount-path=/sonatype-work/ --type persistentVolumeClaim --claim-name=nexus-pvc
oc scale deployments/nexus --replicas=1 -n cicd
oc set volumes deployments/nexus
oc expose svc/nexus -n cicd

echo “Create Gitea template …”
oc create serviceaccount gitea -n cicd
oc adm policy add-scc-to-user anyuid system:serviceaccount:cicd:gitea -n cicd
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/gitea-persistent-storageclass-param.yaml -n cicd
echo “You can provision Gitea repository now from service catalog if you want …”
echo "Press [Enter] key to resume..."
read 

echo "Make sure Openshift Pipeline Operator is installed in cicd project/namespace"
echo "Press [Enter] key to resume..."
read
echo “Create Tekton Pipeline for Java App ...”  
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/sonarqube-scanner-with-login-param.yaml -n cicd
oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/send-to-webhook-slack/0.1/send-to-webhook-slack.yaml
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/tekton.yaml -n cicd

echo "kind: Secret
apiVersion: v1
metadata:
  name: webhook-secret
stringData:
  url: $1" | oc create -f -

oc policy add-role-to-user edit system:serviceaccount:cicd:pipeline -n dev

echo “Create Tekton Pipeline for dotnet corea App ...” 
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_dotnet/main/cicd/dotnet-sonarqube-scanner-with-login-param.yaml -n cicd
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_dotnet/main/cicd/dotnet-test.yaml -n cicd

oc apply -f https://raw.githubusercontent.com/osa-ora/simple_dotnet/main/cicd/tekton.yaml -n cicd

echo "Make sure tkn command line tool is available in your command prompt"
echo "Press [Enter] key to resume..."
read
echo “Running Tekton pipeline for Java app …”
tkn pipeline start my-maven-app-pipeline --param first-run=true --workspace name=maven-workspace,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/pipelines-1.5/01_pipeline/03_persistent_volume_claim.yaml
echo “Running Tekton pipeline for dotnet core app …”
tkn pipeline start my-dotnet-app-pipeline --param first-run=true --workspace name=dotnet-workspace,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/pipelines-1.5/01_pipeline/03_persistent_volume_claim.yaml

echo “Done!!” 
