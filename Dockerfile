FROM fedora:24
LABEL Description="Esta imagen sirve para contenedor de triplo-quickstart" Version="1.0"

ARG ssh_key
ARG uid
ARG user
ENV SSH_KEY_PATH $ssh_key
ENV UID $uid
ENV USER $user


WORKDIR /root
RUN yum install -y openssh-clients sudo
RUN groupadd -g $UID $USER  && useradd -ms /bin/bash -g $USER -u $UID $USER
ADD tripleo-quickstart/quickstart.sh /home/${user}/tripleo-quickstart/quickstart.sh
RUN bash /home/${user}/tripleo-quickstart/quickstart.sh --install-deps

USER $USER
WORKDIR /home/${user}/

RUN echo "cd /home/${user}/tripleo-quickstart" >> .bashrc

CMD /bin/bash
