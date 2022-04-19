KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g Kubernetes -n k8s-ip | jq -r '.ipAddress')

for worker in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'worker')].{name: name, ip: privateIps}" | jq -c '.[]');
  do
    name=$(echo "${worker}" | jq -r '.name')

    index=$(echo ${name/*-})
    port=2202${index}

    ssh-keyscan -H -p $port ${KUBERNETES_PUBLIC_ADDRESS} >> ~/.ssh/known_hosts

    scp -P $port ca.pem ${name}-key.pem ${name}.pem adminuser@${KUBERNETES_PUBLIC_ADDRESS}:~/
  done

for worker in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'worker')].{name: name, ip: privateIps}" | jq -c '.[]');
  do
    name=$(echo "${worker}" | jq -r '.name')
    index=$(echo ${name/*-})
    port=2201${index}

    ssh-keyscan -H -p $port ${KUBERNETES_PUBLIC_ADDRESS} >> ~/.ssh/known_hosts

    scp -P $port service-account-key.pem service-account.pem adminuser@${KUBERNETES_PUBLIC_ADDRESS}:~/
  done