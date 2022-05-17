KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g Kubernetes -n k8s-ip | jq -r '.ipAddress')

for worker in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'worker')].{name: name, ip: privateIps}" | jq -c '.[]');
  do
    name=$(echo "${worker}" | jq -r '.name')

    index=$(echo ${name/*-})
    port=2202${index}

    ssh-keyscan -H -p $port ${KUBERNETES_PUBLIC_ADDRESS} >> ~/.ssh/known_hosts

    scp -P $port ${name}.kubeconfig kube-proxy.kubeconfig adminuser@${KUBERNETES_PUBLIC_ADDRESS}:~/
  done

for controller in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'controller')].{name: name, ip: privateIps}" | jq -c '.[]');
  do
    name=$(echo "${controller}" | jq -r '.name')
    index=$(echo ${name/*-})
    port=2201${index}

    ssh-keyscan -H -p $port ${KUBERNETES_PUBLIC_ADDRESS} >> ~/.ssh/known_hosts

    scp -P $port admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig adminuser@${KUBERNETES_PUBLIC_ADDRESS}:~/
  done