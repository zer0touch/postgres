# vim:set ft=dockerfile:
MAINTAINER Ryan Harper <ryanharper007@zer0touch.co.uk>
FROM debian:jessie
ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
ENV POSTGRES_USER artifactory
ENV DEBIAN_FRONTEND noninteractive
ENV PG_MAJOR 9.4
ENV PG_VERSION 9.4.1-2jessie
ENV LANG en_US.utf8
ENV DEBIAN_FRONTEND noninteractive
ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
ENV POSTGRES_USER artifactory
VOLUME /var/lib/postgresql/data


# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r postgres && useradd -r -g postgres postgres

# grab gosu for easy step-down from root
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
  && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
  && chmod +x /usr/local/bin/gosu \
  && apt-get purge -y --auto-remove curl

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN mkdir /docker-entrypoint-initdb.d

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
  && curl http://packages.2ndquadrant.com/bdr/apt/AA7A6805.asc | apt-key add - \
  && apt-get purge -y --auto-remove curl

RUN echo 'deb http://packages.2ndquadrant.com/bdr/apt/ jessie-2ndquadrant main ' > /etc/apt/sources.list.d/2ndquadrant.list

RUN apt-get update \
  && apt-get install -y postgresql-common \
  && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
  && apt-get install -y \
    postgresql-bdr-$PG_MAJOR=$PG_VERSION \
    postgresql-bdr-contrib-$PG_MAJOR=$PG_VERSION \
    postgresql-bdr-$PG_MAJOR-bdr-plugin \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
