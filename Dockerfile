FROM local/c7-systemd

WORKDIR /opt/wso2
COPY ./etc/systemd/system/multi-user.target.wants/wso2ei.service /etc/systemd/system/multi-user.target.wants/wso2ei6.service
COPY ./etc/sysconfig/wso2ei6 /etc/sysconfig/wso2ei6

RUN yum -y update && yum clean all \
    && yum -y install wget \
    && wget https://bintray.com/wso2/rpm/rpm -O bintray-wso2-rpm.repo \
    && mv bintray-wso2-rpm.repo /etc/yum.repos.d/ \
    && yum install -y sudo \
    && yum install -y wso2ei-6.5.0 \
    && groupadd -g 5463 wso2adm \
    && yum install -y openssl \
    && useradd -d /opt/wso2 -c "wso2 account" -g wso2adm -m -s /bin/bash -u 5460 -p "$(openssl passwd -1 wso2adm)" wso2adm \
    && yum clean all \
    && systemctl enable wso2ei6.service

EXPOSE 9443
RUN ["/usr/sbin/init"]

