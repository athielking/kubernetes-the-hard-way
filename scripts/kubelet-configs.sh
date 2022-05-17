KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g Kubernetes -n k8s-ip | jq -r '.ipAddress')

for worker in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'worker')].{name: name, ip: privateIps}" | jq -c '.[]');
do
  name=$(echo "${worker}" | jq -r '.name')
  ip=$(echo "${worker}" | jq -r '.ip')

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${name}.kubeconfig

  kubectl config set-credentials system:node:${name} \
    --client-certificate=${name}.pem \
    --client-key=${name}-key.pem \
    --embed-certs=true \
    --kubeconfig=${name}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${name} \
    --kubeconfig=${instance}.kubeconfig


  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
 done