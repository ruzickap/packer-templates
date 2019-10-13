#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Update the box
apt-get remove -y --purge aisleriot
apt autoremove -y

echo "Install Oh My Zsh (https://dev.to/mskian/install-z-shell-oh-my-zsh-on-ubuntu-1804-lts-4cm4)"
apt-get install -y powerline fonts-powerline zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git /usr/share/oh-my-zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "/usr/share/zsh-syntax-highlighting" --depth 1
echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "/usr/share/oh-my-zsh/templates/zshrc.zsh-template"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' /usr/share/oh-my-zsh/templates/zshrc.zsh-template
sed -i 's!ZSH=$HOME/.oh-my-zsh!ZSH=/usr/share/oh-my-zsh!' /usr/share/oh-my-zsh/templates/zshrc.zsh-template
echo "autoload -U +X bashcompinit && bashcompinit" >> /usr/share/oh-my-zsh/templates/zshrc.zsh-template
echo "complete -o nospace -C /usr/bin/packer packer" >> /usr/share/oh-my-zsh/templates/zshrc.zsh-template
echo "complete -o nospace -C /usr/bin/terraform terraform" >> /usr/share/oh-my-zsh/templates/zshrc.zsh-template
echo "complete -o nospace -C /usr/bin/vault vault" >> /usr/share/oh-my-zsh/templates/zshrc.zsh-template
cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /home/vagrant/.zshrc
cp /usr/share/oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc
chown vagrant:vagrant /home/vagrant/.zshrc
chsh -s /bin/zsh root
chsh -s /bin/zsh vagrant

cd /tmp

echo "Install Packer"
wget "https://releases.hashicorp.com/packer/1.4.4/packer_1.4.4_linux_amd64.zip" -O /tmp/packer.zip
unzip /tmp/packer.zip
mv /tmp/packer /usr/bin/packer
chown 755 /usr/bin/packer
rm /tmp/packer.zip
packer -autocomplete-install

echo "Install Terraform"
wget "https://releases.hashicorp.com/terraform/0.12.10/terraform_0.12.10_linux_amd64.zip" -O /tmp/terraform.zip
unzip terraform.zip
mv /tmp/terraform /usr/bin/terraform
chown 755 /usr/bin/terraform
rm /tmp/terraform.zip
terraform -install-autocomplete

echo "Install Vault"
wget "https://releases.hashicorp.com/vault/1.2.3/vault_1.2.3_linux_amd64.zip" -O /tmp/vault.zip
unzip /tmp/vault.zip
mv /tmp/vault /usr/bin/vault
chown 755 /usr/bin/vault
rm /tmp/vault.zip
vault -autocomplete-install

echo "Install Minio mc cloient"
wget "https://dl.min.io/client/mc/release/linux-amd64/mc" -O /usr/bin/mc
chmod 755 /usr/bin/mc
chsh -s /bin/zsh

echo "Install Slack VScode Keepass helm kubectl"
snap install slack --classic
snap install code --classic
snap install keepassxc
snap install helm --classic
snap install kubectl --classic

echo "Install docker"
/usr/bin/curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vagrant
curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
apt-get install -y python-docker python3-docker

echo "Install ansible-modules-hashivault"
pip install ansible-modules-hashivault

su vagrant -c "/snap/bin/code --install-extension bungcip.better-toml"
su vagrant -c "/snap/bin/code --install-extension fatihacet.gitlab-workflow"
su vagrant -c "/snap/bin/code --install-extension jasonn-porch.gitlab-mr"
su vagrant -c "/snap/bin/code --install-extension jgsqware.gitlab-ci-templates"
su vagrant -c "/snap/bin/code --install-extension mauve.terraform"
su vagrant -c "/snap/bin/code --install-extension ms-azuretools.vscode-docker"
su vagrant -c "/snap/bin/code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools"
su vagrant -c "/snap/bin/code --install-extension ms-python.python"
su vagrant -c "/snap/bin/code --install-extension redhat.vscode-yaml"
su vagrant -c "/snap/bin/code --install-extension vscoss.vscode-ansible"
su vagrant -c "/snap/bin/code --install-extension ziyasal.vscode-open-in-github"