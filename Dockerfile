FROM fedora:24
LABEL Description="Esta imagen sirve para contenedor de triplo-quickstart" Version="1.0"

WORKDIR /root
RUN yum install -y openssh-clients sudo
ADD tripleo-quickstart/quickstart.sh /root/tripleo-quickstart/quickstart.sh
RUN mkdir -p /root/.ssh/
RUN chmod 700 /root/.ssh/
RUN bash /root/tripleo-quickstart/quickstart.sh --install-deps
RUN echo "cd /root/tripleo-quickstart" >> .bashrc

CMD /bin/bash
