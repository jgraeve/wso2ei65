#FROM local/c7-systemd
FROM centos:7

ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

WORKDIR /usr/lib64/wso2

RUN yum -y update && yum clean all
ARG JAVA_HOME
RUN yum -y install wget \
    && wget https://bintray.com/wso2/rpm/rpm -O bintray-wso2-rpm.repo \
    && mv bintray-wso2-rpm.repo /etc/yum.repos.d/ \
    && yum install -y sudo \
    && yum install -y java \
    && yum install -y wso2ei-6.5.0 \
# create wso2adm user & group
    && groupadd -g 5463 wso2adm \
    && yum install -y openssl \
    && useradd -d /home/wso2adm -c "wso2 account" -g wso2adm -s /bin/bash -u 5460 -p "$(openssl passwd -1 wso2adm)" wso2adm \
    && echo set -a >> ~wso2adm/.profile \
    && echo "JAVA_HOME=${JAVA_HOME}" >> ~wso2adm/.profile \
    && echo 'PATH=${JAVA_HOME}/bin:${PATH}' >> ~wso2adm/.profile \    
    && chown -R wso2adm:wso2adm /usr/lib64/wso2
# setup service wso2ei6
COPY ./usr/lib/systemd/system/wso2ei6.service /usr/lib/systemd/system/wso2ei6.service
COPY ./etc/sysconfig/wso2ei6 /etc/sysconfig/wso2ei6
RUN systemctl enable wso2ei6.service
# install wum, add product wso2ei6 and update to latest version
RUN wget http://product-dist.wso2.com/downloads/wum/3.0.6/wum-3.0.6-linux-x64.tar.gz \
    && tar xvfz wum-3.0.6-linux-x64.tar.gz \
    && rm -f wum-3.0.6-linux-x64.tar.gz
ARG WUM_EMAIL
ARG WUM_PASSWORD
RUN wum/bin/wum init -u ${WUM_EMAIL} --password ${WUM_PASSWORD} \
  && echo Y|wum/bin/wum add wso2ei-6.5.0 \
  && wum/bin/wum update wso2ei-6.5.0
# clean previous installation
RUN rm -rf /usr/lib64/wso2/wso2ei/6.5.0/*
RUN yum install -y unzip
# install patched version of wso2ei
RUN cd /root/.wum3/products/wso2ei/6.5.0/full \
  && unzip wso2ei-6.5.0*.zip \
  && mv wso2ei-6.5.0/* /usr/lib64/wso2/wso2ei/6.5.0/ \
  && chown -R wso2adm:wso2adm /usr/lib64/wso2 \
  && rm -rf /root/.wum3/products/wso2ei/6.5.0/full/wso2ei-6.5.0
  
RUN yum install -y unzip
EXPOSE 9443
CMD ["/usr/sbin/init"]
