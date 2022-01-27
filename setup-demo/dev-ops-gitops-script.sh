#!/bin/sh
if [ "$#" -ne 3 ];  then
  echo "Usage: $0 dev-project cicd-project slack_url" >&2
  exit 1
fi

echo "Please Login to OCP using oc login ..... "  
echo "Make sure Openshift Pipeline Operator is installed"
echo "Make sure oc and tkn commands are installed"
echo "Dev Project $1 CI-CD Project $2"
echo "Slack url: $3"
echo "Press [Enter] key to resume..." 
read

echo "Create Required Projects … $1 - $2" 
oc new-project $1 
oc new-project $2

echo "Create SonarQube for static code analysis …" 
oc process -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/sonarqube-persistent-template.yaml | oc create -f - -n $2

echo "Make sure Openshift Pipeline Operator is installed in $2 project/namespace"
echo "Press [Enter] key to resume..."
read
echo "Create Tekton Pipeline for Java App ..."
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/sonarqube-scanner-with-login-param.yaml -n $2
oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/send-to-webhook-slack/0.1/send-to-webhook-slack.yaml -n $2
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_java_maven/main/cicd/tekton.yaml -n $2

echo "kind: Secret
apiVersion: v1
metadata:
  name: webhook-secret
  namespace: $2
stringData:
  url: $3" | oc create -f -

oc policy add-role-to-user edit system:serviceaccount:$2:pipeline -n $1

echo "Create Tekton Pipeline for dotnet corea App ..."
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_dotnet/main/cicd/dotnet-sonarqube-scanner-with-login-param.yaml -n $2
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_dotnet/main/cicd/dotnet-test.yaml -n $2
oc apply -f https://raw.githubusercontent.com/osa-ora/simple_dotnet/main/cicd/tekton.yaml -n $2

echo "Make sure tkn command line tool is available in your command prompt"
echo "Press [Enter] key to resume..."
read
echo "Running Tekton pipeline for Java app …"
tkn pipeline start my-maven-app-pipeline --param first-run=true --param project-name=$1 --workspace name=maven-workspace,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/pipelines-1.5/01_pipeline/03_persistent_volume_claim.yaml
echo "Running Tekton pipeline for dotnet core app …"
tkn pipeline start my-dotnet-app-pipeline --param first-run=true --param project-name=$1 --workspace name=dotnet-workspace,volumeClaimTemplateFile=https://raw.githubusercontent.com/openshift/pipelines-tutorial/pipelines-1.5/01_pipeline/03_persistent_volume_claim.yaml

echo "Done!!"
