FROM centos:latest


USER root
ARG DISTRO_NAME=flink-1.3.0

RUN yum install -y epel-release tar java && \
    yum clean all

RUN curl -o /etc/yum.repos.d/mperezco-eidenworks-epel-7.repo https://copr.fedorainfracloud.org/coprs/mperezco/eidenworks/repo/epel-7/mperezco-eidenworks-epel-7.repo &&\
    yum -y install flink &&\
    yum clean all

# when the containers are not run w/ uid 0, the uid may not map in
# /etc/passwd and it may not be possible to modify things like
# /etc/hosts. nss_wrapper provides an LD_PRELOAD way to modify passwd
# and hosts.
RUN yum install -y nss_wrapper numpy && yum clean all

ENV PATH=$PATH:/opt/flink/bin
ENV FLINKK_HOME=/opt/flink

# Add scripts used to configure the image
#COPY scripts /tmp/scripts


# Custom scripts
#RUN [ "bash", "-x", "/tmp/scripts/flink/install" ]

# Cleanup the scripts directory
#RUN rm -rf /tmp/scripts

# Switch to the user 372 assigned to flink in the RPM
USER 372

# Make the default PWD somewhere that the user can write. This is
# useful when connecting with 'oc run' and starting a 'flink-shell',
# which will likely try to create files and directories in PWD and
# error out if it cannot.
WORKDIR /tmp

ENTRYPOINT ["/entrypoint"]

# Start the main process
CMD ["/opt/flink/bin/start-cluster.sh"]
