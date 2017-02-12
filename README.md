# tripleo-semilla
Docker container for tripleo-quickstart.

# Container for Quickstart TripleO
Docker container for tripleo-quickstart. It is intended to be a seed to generate an isolated workspace

Requires [tripleo-quickstart](https://github.com/openstack/tripleo-quickstart)

# Example on how to build the container
> Operating System: Ubuntu

## Install Docker
Based on docs from [Docker](https://docs.docker.com/engine/installation/linux/ubuntu/)
``` bash
sudo apt-get update

# Extra packages
sudo apt-get install curl \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual

# Repo config
sudo apt-get install apt-transport-https \
                       software-properties-common \
                       ca-certificates

# Official GPG key from Docker
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -

# Validate key 58118E89F3A912897C070ADBF76221572C52609D
$(apt-key fingerprint 58118E89F3A912897C070ADBF76221572C526091 | wc -l | grep -qv 0) && echo Verificado || echo "Error de verificacion"

# Install stable repo
sudo apt-get install software-properties-common
sudo add-apt-repository \
       "deb https://apt.dockerproject.org/repo/ \
       ubuntu-$(lsb_release -cs) \
       main"

# Install Docker
sudo apt-get update
sudo apt-get -y install docker-engine

# User and group
sudo groupadd docker:
sudo usermod -aG docker $USER

# Validate install
sudo docker run hello-world
```
## Before build
Consider the following steps before building the container

### 1. Set enviroment
``` bash
cat << "_EOF" > "oooq.env"
export VIRTHOST=${VIRTHOST:-localhost}                          # IP de la maqina física para generar ambiente virtual
export WORKDIR=${WORKDIR:-"$HOME/tripleo"}                      # Directorio de trabajo
export SEED=${SEED:-"${WORKDIR}/tripleo-semilla"}               # Directorio de este repo
export OPT_WORKDIR=${OPT_WORKDIR:-"${WORKDIR}/.quickstart"}     # Directorio de despliegue de oooq
export OOOQ_DIR=${OOOQ_DIR:-"${WORKDIR}/tripleo-quickstart"}    # Directorio del repo de oooq
export SSH_KEYS=${SSH_KEY:-"${HOME}/.ssh"}                      # Llave ssh para autenticación sin contraseña
_EOF
mv oooq.env "$WORKDIR"
cd "$WORKDIR"
```
*Remember to check and change **VIRTHOST**=~~localhost~~ accordingly*
``` bash
sed -i "s@localhost@<VIRTHOST_IP>@" oooq.env
source oooq.env
```
### 2. Check or create directory structure
The working direcotory is a workspace to share with the container and to persist data
``` bash
mkdir -p "$OPT_WORKDIR"
git clone https://github.com/openstack/tripleo-quickstart "$OOOQ_DIR"
git clone https://github.com/jobcespedes/tripleo-semilla.git "$SEED"
```
### 3. Check access to $VIRTHOST without password
``` bash
# Use keys from current user
cat "${SSH_KEYS}/id_rsa.pub" | ssh root@$VIRTHOST 'cat >> .ssh/authorized_keys'
# Test
ssh root@$VIRTHOST uname -a

# Or generate a new key just for the project
## ssh-keygen -q -t rsa -N "" -f "${SSH_KEYS}/id_rsa"
## cat "${SSH_KEYS}/id_rsa.pub" | ssh root@$VIRTHOST 'cat >> .ssh/authorized_keys'
## chmod 700 "${SSH_KEYS}" && chmod 600 "${SSH_KEYS}/id_rsa"*
## ssh root@$VIRTHOST -i "${SSH_KEYS}/id_rsa" uname -a
```
## Build the container
``` bash
docker build -t tripleo/semilla -f "${WORKDIR}/tripleo-semilla/Dockerfile" .
```
## Run the container
``` bash
docker run --net=host -it  \
    -v "$WORKDIR/.quickstart":/root/.quickstart \
    -v "$SSH_KEYS":/root/.ssh \
    -v "$WORKDIR/tripleo-quickstart":/root/tripleo-quickstart \
    -e USER=root -e VIRTHOST=$VIRTHOST \
    tripleo/semilla
```
## Inside the container
Once in the container you can run tripleo-quickstart.
### Run tripleo-quickstart script
``` bash
# Option -n does not clone tripleo-quickstart
# Option -t does all phases
# Using rest of default options
bash quickstart.sh -n -t all $VIRTHOST
```
### Accesing overcloud Dashboard
Once the script finish succesfully, you can access Dashboar from your workstation.
``` bash
ssh -F $HOME/.quickstart/ssh.config.ansible \
  -D 1080 undercloud
# Firefox proxy config. Check doc in:
# http://docs.openstack.org/developer/tripleo-quickstart/accessing-overcloud.html#using-firefox
```
Dashboard URL would be http://\<overcloud\_public\_vip\>. This IP could be find with:
``` bash
grep overcloud_public_vip tripleo-quickstart/roles/common/defaults/main.yml
```
# Pura vida
