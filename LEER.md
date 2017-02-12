# Semilla Quickstart TripleO
Archivo para generar imagen de un contenedor semilla de un ambiente TripleO

Utiliza [tripleo-quickstart](https://github.com/openstack/tripleo-quickstart)

# Ejemplo de como construir la imagen
> Sistema Operativo: Ubuntu

## Instalar Docker
A partir de instrucciones en [la documentación de Docker](https://docs.docker.com/engine/installation/linux/ubuntu/)
``` bash
sudo apt-get update

# Paquetes extra
sudo apt-get install curl \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual

#Configurar el repositorio
sudo apt-get install apt-transport-https \
                       software-properties-common \
                       ca-certificates

# Agregar llave oficial GPG de docker
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -

# Validar que llave sea 58118E89F3A912897C070ADBF76221572C52609D
$(apt-key fingerprint 58118E89F3A912897C070ADBF76221572C526091 | wc -l | grep -qv 0) && echo Verificado || echo "Error de verificacion"

# Instalar repositorio estable
sudo apt-get install software-properties-common
sudo add-apt-repository \
       "deb https://apt.dockerproject.org/repo/ \
       ubuntu-$(lsb_release -cs) \
       main"

# Instalar docker
sudo apt-get update
sudo apt-get -y install docker-engine

# Usuarios y grupos
sudo groupadd docker
sudo usermod -aG docker $USER

# Verificar la instalación
sudo docker run hello-world
```
## Previo a construir el contenedor
Considere lo siguiente previo a construir el contenedor

### 1. Prepare el entorno y sus variables.

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
*Recuerde revisar y cambiar la variable **VIRTHOST**=~~localhost~~*
``` bash
sed -i "s@localhost@<VIRTHOST_IP>@" oooq.env
source oooq.env
```
### 2. Verifique la existencia de los directorios
En una carpeta de trabajo para compartir con el contenedor debe estar los repositorios.
``` bash
mkdir -p "$OPT_WORKDIR"
git clone https://github.com/openstack/tripleo-quickstart "$OOOQ_DIR"
git clone https://github.com/jobcespedes/tripleo-semilla.git "$SEED"
```
### 3. Verifique el ingreso sin contraseña a $VIRTHOST
``` bash
# Utilizar la llave del usuario actual. Requiere introducir una vez la contraseña.
cat "${SSH_KEYS}/id_rsa.pub" | ssh root@$VIRTHOST 'cat >> .ssh/authorized_keys'
# Probar
ssh root@$VIRTHOST uname -a

# Puede generar una llave nueva
## ssh-keygen -q -t rsa -N "" -f "${SSH_KEYS}/id_rsa"
## cat "${SSH_KEYS}/id_rsa.pub" | ssh root@$VIRTHOST 'cat >> .ssh/authorized_keys'
## chmod 700 "${SSH_KEYS}" && chmod 600 "${SSH_KEYS}/id_rsa"*
## ssh root@$VIRTHOST -i "${SSH_KEYS}/id_rsa" uname -a
```
## Construir el contenedor
``` bash
docker build -t tripleo/semilla -f "${WORKDIR}/tripleo-semilla/Dockerfile" .
```
## Correr el contenedor
``` bash
docker run --net=host -it  \
    -v "$WORKDIR/.quickstart":/root/.quickstart \
    -v "$SSH_KEYS":/root/.ssh \
    -v "$WORKDIR/tripleo-quickstart":/root/tripleo-quickstart \
    -e USER=root -e VIRTHOST=$VIRTHOST \
    tripleo/semilla
```
## Dentro del contenedor
Una vez dentro del contenedor se puede correr tripleo-quickstart. Una vez finalizado se puede ingresar al Dashboard del Open Stack en el overcloud
### Correr tripleo-quickstart
``` bash
# La opción -n es para no clonar el repo tripleo-quickstart
# La opción -t es para que realice todos las fases
# Las demás opciones son por defecto
bash quickstart.sh -n -t all $VIRTHOST
```
### Acceso al dashboard desde la maquina de trabajo
``` bash
ssh -F $HOME/.quickstart/ssh.config.ansible \
  -D 1080 undercloud
# Configurar un proxy en firefox
# Ver más indicaciones en:
# http://docs.openstack.org/developer/tripleo-quickstart/accessing-overcloud.html#using-firefox
```
La URL serian http://\<overcloud\_public\_vip\>. Esta IP se puede buscar con:
``` bash
grep overcloud_public_vip tripleo-quickstart/roles/common/defaults/main.yml
```
