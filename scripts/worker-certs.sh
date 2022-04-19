
for worker in $(az vm list -g "Kubernetes" -d --query "[? contains(name, 'worker')].{name: name, ip: privateIps}" | jq -c '.[]');
do
  name=$(echo "${worker}" | jq -r '.name')
  ip=$(echo "${worker}" | jq -r '.ip')

  rm -f ${name}-csr.json
  rm -f ${name}.csr
  rm -f ${name}-key.pem   
  rm -f ${name}.pem

  cat > ${name}-csr.json <<EOF
{
  "CN": "system:node:${name}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

   cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${name},${ip} \
    -profile=kubernetes \
    ${name}-csr.json | cfssljson -bare ${name}
 done