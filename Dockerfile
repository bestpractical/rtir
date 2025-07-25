FROM bpssysadmin/rt-base-debian:RT-6.0.0-bullseye-20250509

LABEL maintainer="Best Practical Solutions <contact@bestpractical.com>"

# Valid values are RT branches like 5.0-trunk or version tags like rt-4.4.4
ARG RT_VERSION=6.0-trunk
ARG RT_DB_NAME=rt6
ARG RT_DB_TYPE=mysql
ARG RT_DBA_USER=root
ARG RT_DBA_PASSWORD=password
ARG RT_TEST_DB_HOST=172.17.0.2
ARG RT_TEST_RT_HOST

ENV PATH="/opt/perl/bin:$PATH"

RUN cd /usr/local/src \
  && git clone https://github.com/bestpractical/rt.git \
  && cd rt \
  && git checkout $RT_VERSION \
  && ./configure.ac \
     --enable-developer \
     --enable-gd \
     --enable-graphviz \
     --with-db-type="$RT_DB_TYPE" \
     --with-db-database="$RT_DB_NAME" \
     --with-db-host="$RT_TEST_DB_HOST" \
     --with-db-rt-host="${RT_TEST_RT_HOST:-$(ip --oneline address show to 172.16/12 | gawk '{split($4, a, "/"); print a[1] "/255.255.255.0"; exit 0;}')}" \
  && make install \
  && perl -I/opt/rt6/local/lib -I/opt/rt6/lib sbin/rt-setup-database --action init --dba="$RT_DBA_USER" --dba-password="$RT_DBA_PASSWORD" \
  && rm -rf /usr/local/src/*

RUN cpm install --global --no-prebuilt --test --with-all --show-build-log-on-failure Net::Domain::TLD Net::Whois::RIPE Parse::BooleanLogic Geo::IPinfo

ENV RT_DBA_USER="$RT_DBA_USER"
ENV RT_DBA_PASSWORD="$RT_DBA_PASSWORD"
ENV RT_TEST_DEVEL=1

CMD tail -f /dev/null
