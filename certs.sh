rm -rf .certs
mkdir .certs
pushd ".certs"

echo -e "\e[32m Creating CA Certificates \e[0m"
bash ../scripts/cert-authority.sh

echo -e "\e[32m Creating Admin Certificate \e[0m"
bash ../scripts/admin-client-cert.sh

echo -e "\e[32m Creating Kubelet Client Certificates \e[0m"
bash ../scripts/kubelet-client-certs.sh

echo -e "\e[32m Creating Controller Manager Client Certificates \e[0m"
bash ../scripts/kube-controller-manager.sh

echo -e "\e[32m Creating Kube Proxy Client Certificates \e[0m"
bash ../scripts/kube-proxy.sh

echo -e "\e[32m Creating Kube Scheduler Client Certificate \e[0m"
bash ../scripts/kube-scheduler.sh

echo -e "\e[32m Creating Kube API Server Certificate \e[0m"
bash ../scripts/kube-api.sh

echo -e "\e[32m Creating Service Account Certificate \e[0m"
bash ../scripts/service-account.sh

echo -e "\e[32m Uploading Certificates...\e[0m"
bash ../scripts/upload-certs.sh

echo -e "\e[32m Creating Kubelet Config Files \e[0m"
bash ../scripts/kubelet-configs.sh

echo -e "\e[32m Creating Kube Proxy Config Files \e[0m"
bash ../scripts/kube-proxy-config.sh

echo -e "\e[32m Creating Kube Controller Manager Config Files \e[0m"
bash ../scripts/kube-controller-manager-config.sh

echo -e "\e[32m Creating Kube Scheduler Config Files \e[0m"
bash ../scripts/kube-scheduler-config.sh

echo -e "\e[32m Creating Admin Config Files \e[0m"
bash ../scripts/admin-config.sh

echo -e "\e[32m Uploading Configuration Files...\e[0m"
bash ../scripts/upload-configs.sh

echo -e "\e[32m Generate and Upload Encryption Configuration Files...\e[0m"
bash ../scripts/encryption-config.sh