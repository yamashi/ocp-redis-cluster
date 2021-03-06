FROM centos:7
MAINTAINER Marcos Entenza <mak@redhat.com>

LABEL io.k8s.description="3 Node Redis Cluster" \
      io.k8s.display-name="Redis Cluster" \
      io.openshift.expose-services="6379:tcp" \
      io.openshift.tags="redis-cluster"

RUN groupadd -r redis && useradd -r -g redis -d /home/redis -m redis

RUN yum update -y && \
yum install -y make gcc rubygems nmap-ncat && yum clean all

CMD ruby --version

WORKDIR /tmp/

RUN curl https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz -o /tmp/ruby-2.3.0.tar.gz
RUN echo "ba5ba60e5f1aa21b4ef8e9bf35b9ddb57286cb546aac4b5a28c71f459467e507 /tmp/ruby-2.3.0.tar.gz" > /tmp/ruby-2.3.0-sha256sum
RUN sha256sum -c /tmp/ruby-2.3.0-sha256sum
RUN tar xf /tmp/ruby-2.3.0.tar.gz
RUN /tmp/ruby-2.3.0/configure
RUN make
RUN make install

RUN rm -rf /tmp/*

RUN echo "151.101.64.70 rubygems.org">> /etc/hosts && \
gem install redis

WORKDIR /usr/local/src/

RUN curl -o redis-3.2.6.tar.gz http://download.redis.io/releases/redis-3.2.6.tar.gz && \
tar xzf redis-3.2.6.tar.gz && \
cd redis-3.2.6 && \
make MALLOC=libc

RUN for file in $(grep -r --exclude=*.h --exclude=*.o /usr/local/src/redis-3.2.6/src | awk {'print $3'}); do cp $file /usr/local/bin; done && \
cp /usr/local/src/redis-3.2.6/src/redis-trib.rb /usr/local/bin && \
cp -r /usr/local/src/redis-3.2.6/utils /usr/local/bin && \
rm -rf /usr/local/src/redis*

COPY src/redis.conf /usr/local/etc/redis.conf
COPY src/*.sh /usr/local/bin/
COPY src/redis-trib.rb /usr/local/bin/


RUN mkdir /data && chown redis:redis /data && \
chown -R redis:redis /usr/local/bin/ && \
chown -R redis:redis /usr/local/etc/ && \
chmod +x /usr/local/bin/cluster-init.sh /usr/local/bin/redis-trib.rb

VOLUME /data
WORKDIR /data

USER redis

EXPOSE 6379 16379

CMD [ "redis-server", "/usr/local/etc/redis.conf" ]
