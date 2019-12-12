FROM local/c7-systemd

WORKDIR /opt/wso2
COPY ./usr/lib/systemd/system/wso2ei6.service /usr/lib/systemd/system/wso2ei6.service
COPY ./etc/sysconfig/wso2ei6 /etc/sysconfig/wso2ei6

RUN yum -y update && yum clean all
RUN yum -y install wget \
    && wget https://bintray.com/wso2/rpm/rpm -O bintray-wso2-rpm.repo \
    && mv bintray-wso2-rpm.repo /etc/yum.repos.d/ \
    && yum install -y sudo \
    && yum install -y wso2ei-6.5.0 \
    && groupadd -g 5463 wso2adm \
    && yum install -y openssl \
    && useradd -d /home/wso2adm -c "wso2 account" -g wso2adm -s /bin/bash -u 5460 -p "$(openssl passwd -1 wso2adm)" wso2adm \
    && yum clean all \
    && ln -s /usr/lib/systemd/system/wso2ei6.service /etc/systemd/system/multi-user.target.wants/wso2ei6.service \
    && systemctl enable wso2ei6.service
RUN wget http://product-dist.wso2.com/downloads/wum/3.0.6/wum-3.0.6-linux-x64.tar.gz \
    && tar xvfz wum-3.0.6-linux-x64.tar.gz \
    && rm -f wum-3.0.6-linux-x64.tar.gz
ARG WUM_EMAIL
ARG WUM_PASSWORD
RUN wum/bin/wum init -u ${WUM_EMAIL} --password ${WUM_PASSWORD} \
  && echo Y|wum/bin/wum add wso2ei-6.5.0 \
  && wum/bin/wum update wso2ei-6.5.0
RUN yum install -y  unzip
RUN rm -rf /usr/lib64/wso2/wso2ei/6.5.0/*
RUN cd /root/.wum3/products/wso2ei/6.5.0/full \
  && unzip wso2ei-6.5.0*.zip \
  && mv wso2ei-6.5.0/* /usr/lib64/wso2/wso2ei/6.5.0/ \
  && rm -rf /root/.wum3/products/wso2ei/6.5.0/full/wso2ei-6.5.0
EXPOSE 9443
RUN ["/usr/sbin/init"]

