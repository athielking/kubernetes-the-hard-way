ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
KUBERNETES_PUBLIC_ADDRESS=$(az network public-ip show -g Kubernetes -n k8s-ip | jq -r '.ipAddress')

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for controller in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'controller')].{name: name, ip: privateIps}" | jq -c '.[]');
  do
    name=$(echo "${controller}" | jq -r '.name')
    index=$(echo ${name/*-})
    port=2201${index}

    ssh-keyscan -H -p $port ${KUBERNETES_PUBLIC_ADDRESS} >> ~/.ssh/known_hosts

    scp -P $port encryption-config.yaml adminuser@${KUBERNETES_PUBLIC_ADDRESS}:~/
  done