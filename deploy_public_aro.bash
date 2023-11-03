#!/bin/bash
############################################################
# options                                                  #
############################################################
# Print the menu
echo "================================================="
echo "Install Public ARO Cluster. Choose an option (1-5): "
echo "================================================="
options=(
  "Terraform Init"
  "Terraform Plan"
  "Terraform Apply"
  "Terraform Destroy"
  "Quit"
)

# Select an option
COLUMNS=0
select opt in "${options[@]}"; do
  case $opt in
  "Terraform Init")
    op="init"
    break
    ;;
  "Terraform Plan")
    op="plan"
    break
    ;;
  "Terraform Apply")
    op="apply"
    break
    ;;
  "Terraform Destroy")
    op="destroy"
    break
    ;;    
  "Quit")
    exit
    ;;
  *) echo "Invalid option $REPLY" ;;
  esac
done

echo 
# ARO cluster name
cluster_name="aro-$(whoami)"

echo "ARO Cluster name=$cluster_name"

pull_secret_path=./pull-secret.txt
location="eastus"

# Subscription id, subscription name, and tenant id of the current subscription
subscriptionId=$(az account show --query id --output tsv)

if [[ -z ${subscriptionId} ]]; then
   echo "Could not get Azure Subcription details. May be Azure login is needed?"
   exit 1
fi 
#subscriptionName=$(az account show --query name --output tsv)
#tenantId=$(az account show --query tenantId --output tsv)

if [[ $op == 'init' ]]; then
  terraform init
elif [[ $op == 'plan' ]]; then
  terraform plan \
    -compact-warnings \
    -out aro.tfplan \
    -var "location=$location" \
    -var "pull_secret_path=$pull_secret_path" \
    -var "subscription_id=$subscriptionId" \
    -var "cluster_name=$cluster_name"
elif [[ $op == 'apply' ]]; then
  if [[ -f "aro.tfplan" ]]; then
    terraform apply \
      -compact-warnings \
      -auto-approve \
      aro.tfplan
    apply_return=$?
  else
    terraform apply \
      -compact-warnings \
      -auto-approve \
      -var "location=$location" \
      -var "pull_secret_path=$pull_secret_path" \
      -var "subscription_id=$subscriptionId" \
      -var "cluster_name=$cluster_name"
    apply_return=$?
  fi
    ##Print varaiables
    if [[ ${apply_return} -eq 0 ]]; then
      echo "ARO is deployed successfully"

      echo "Cluster Name=${cluster_name}"
      echo "Resource Group=${cluster_name}-rg"

      ARO_URL=$(az aro show -n ${cluster_name} -g ${cluster_name}-rg -o json | jq -r '.apiserverProfile.url')
      echo "API Server URL=${ARO_URL}"

      CONSOLE_URL=$(az aro show -n ${cluster_name} -g ${cluster_name}-rg -o json | jq -r '.consoleProfile.url')
      echo "Console URL=${CONSOLE_URL}"

      ARO_USERNAME=$(az aro list-credentials -n ${cluster_name} -g ${cluster_name}-rg -o json | jq -r '.kubeadminUsername')
      ARO_PASSWORD=$(az aro list-credentials -n ${cluster_name} -g ${cluster_name}-rg -o json | jq -r '.kubeadminPassword')    
      echo "ARO Username=${ARO_USERNAME}"
      echo "ARO Password=${ARO_PASSWORD}"
    fi 
elif [[ $op == 'destroy' ]]; then
  export TF_VAR_subscription_id=$subscriptionId && \
  export TF_VAR_pull_secret_path=$pull_secret_path && \
  terraform destroy -auto-approve

  if [[ $? -eq 0 ]]; then
    echo "ARO cluster is destroyed successfully"
  else
    echo "Error in destrying ARO cluster"
  fi
fi

