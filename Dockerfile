FROM bpssysadmin/rt-base-debian-stretch

LABEL maintainer="Best Practical Solutions <contact@bestpractical.com>"

# Valid values are RT branches like 5.0-trunk or version tags like rt-4.4.4
ENV RT_VERSION 5.0-trunk
ENV RT_TEST_DEVEL 1
ENV RT_DBA_USER root
ENV RT_DBA_PASSWORD password
ENV RT_TEST_DB_HOST=172.17.0.2
ENV RT_TEST_RT_HOST=172.17.0.3

RUN cd /usr/local/src \
  && git clone https://github.com/bestpractical/rt.git \
  && cd rt \
  && git checkout $RT_VERSION \
  && ./configure.ac \
    --enable-developer --enable-gd --enable-graphviz --with-db-host=172.17.0.2 --with-db-rt-host=172.17.0.3\
  && make install \
  && /usr/bin/perl -I/opt/rt5/local/lib -I/opt/rt5/lib sbin/rt-setup-database --action init --dba-password=password \
  && rm -rf /usr/local/src/*

RUN cpanm Net::Domain::TLD Net::Whois::RIPE Parse::BooleanLogic

CMD tail -f /dev/null
