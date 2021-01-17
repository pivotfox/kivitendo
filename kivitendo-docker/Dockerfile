FROM debian:buster-slim

LABEL description="kivitendo container"

MAINTAINER Hans-Jürgen Grimminger <info@ptec.de>

# build options
#
ARG VERSION=3.5.6
ARG BUILD_DATE
ARG LOCALE=de_DE
ARG POSTGRES_VERSION=11
ARG KIVITENDO_TEMPLATE=company

# Environment configuration options
#
ENV VERSION=$VERSION
ENV BUILD_DATE=${BUILD_DATE}

ENV locale $LOCALE
ENV postgres_user postgres
ENV postgres_password postgres
ENV postgres_host localhost
ENV kivitendo_version master
ENV kivitendo_user kivitendo
ENV kivitendo_password kivitendo
ENV kivitendo_adminpassword admin123
ENV KIVITENDO_TEMPLATE ${KIVITENDO_TEMPLATE}
ENV kivitendo_branch customize
ENV CRM no
ENV cups_user admin
ENV cups_password admin
ENV webdav_user webdav
ENV webdav_password webdav
ENV root_alias root
ENV kivitendo_crm_version master
ENV kivitendo_crm_branch customize



# set debian locale
#
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i ${locale} -c -f UTF-8 -A /usr/share/locale/locale.alias ${locale}.UTF-8
ENV LANG ${locale}.utf8

# Add backport repository
RUN printf "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list &&\
    printf "# APT PINNING PREFERENCES\nPackage: *\nPin: release a=buster-backports\nPin-Priority: 200\n" > /etc/apt/preferences.d/99backports 

# Install Packages
#
# sections: erp, tex, crm, other
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get -qq update && apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt install -y  \
  apache2 libarchive-zip-perl libclone-perl \
  libconfig-std-perl libdatetime-perl libdbd-pg-perl libdbi-perl \
  libemail-address-perl  libemail-mime-perl libfcgi-perl libjson-perl \
  liblist-moreutils-perl libnet-smtp-ssl-perl libnet-sslglue-perl \
  libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
  librose-db-perl librose-object-perl libsort-naturally-perl \
  libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
  libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl \
  libimage-info-perl libgd-gd2-perl libapache2-mod-fcgid \
  libfile-copy-recursive-perl libalgorithm-checkdigits-perl \
  libcrypt-pbkdf2-perl git libcgi-pm-perl libtext-unidecode-perl libwww-perl \
                  poppler-utils libhtml-restrict-perl \
  libdatetime-set-perl libset-infinite-perl liblist-utilsby-perl \
  libdaemon-generic-perl libfile-flock-perl libfile-slurp-perl \
  libfile-mimeinfo-perl libpbkdf2-tiny-perl libregexp-ipv6-perl \
  libdatetime-event-cron-perl libexception-class-perl libcam-pdf-perl \
  libxml-libxml-perl \
  libpath-tiny-perl \
  \
  texlive-base-bin texlive-latex-recommended texlive-fonts-recommended \
  texlive-latex-extra texlive-lang-german texlive-generic-extra texlive-xetex \
  ghostscript lynx \
  \
  libapache2-mod-php php-gd php-imap php-mail php-mail-mime \
  php-pear php-mdb2 php-mdb2-driver-pgsql php-pgsql  \
  php-fpdf imagemagick fonts-freefont-ttf php-curl \
  libphp-jpgraph php-enchant aspell-de libset-crontab-perl  \
  \
  lsb-release exim4 supervisor sudo gnupg \
  mc \
  make liblog-log4perl-perl

# Install package(s) from backports
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -t buster-backports install -y  \
    aqbanking-tools


# Install PostgreSQL client
#
# Add PostgreSQL's PGP key & repository.
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7FCC7D46ACCC4CF8
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# Install client
RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
    apt-get install -y \
    postgresql-client-${POSTGRES_VERSION}

#
# Add CUPS printing system
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y  \
  cups cups-client cups-bsd \
  cups-filters \
  foomatic-db-compressed-ppds \
  printer-driver-all \
  openprinting-ppds \
  hpijs-ppds \
  hp-ppd \
  hplip \
  whois smbclient

VOLUME  ["/etc/cups"]
EXPOSE 631/tcp 631/udp



# Add Kivitendo
#
# Kivitendo erp & crm download from git repositories
RUN cd /var/www/ && git clone https://github.com/kivitendo/kivitendo-erp.git
RUN cd /var/www/ && git clone https://github.com/kivitendo/kivitendo-crm.git

#
# Set directory permissions
#
RUN mkdir /var/www/kivitendo-erp/webdav /var/www/kivitendo-erp/kivi_documents
RUN mkdir -p /var/www/patches /var/www/patches/erp /var/www/patches/crm
#
RUN chown -R www-data:www-data /var/www
RUN chmod u+rwx,g+rx,o+rx /var/www
RUN find /var/www -type d -exec chmod u+rx,g+rx,o+rx {} +
RUN find /var/www -type f -exec chmod u+r,g+r,o+r {} +

RUN chmod -R u+w,g+w /var/www/kivitendo-erp/users \
                     /var/www/kivitendo-erp/spool \
                     /var/www/kivitendo-erp/templates \
                     /var/www/kivitendo-erp/kivi_documents \
                     /var/www/kivitendo-erp/webdav


# Expose Volumes
#
VOLUME  ["/var/www/kivitendo-erp/templates/$KIVITENDO_TEMPLATE", \
         "/var/www/kivitendo-erp/config", \
         "/var/www/kivitendo-erp/users", \
         "/var/www/kivitendo-erp/webdav", \
         "/var/www/kivitendo-erp/kivi_documents", \
         "/var/www/patches"]

COPY rootfs/ /
RUN chmod +x /usr/local/bin/*.sh && chmod a=rwxt /tmp

# Apache configuration
#
# set modules
RUN a2enmod fcgid ssl dav*
# crm:
RUN a2enmod cgi
# Set apache site config
RUN a2ensite kivitendo && a2dissite 000-default
#
# expose ports of apache
EXPOSE 80 443
 

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Start supervisord to execute all services
CMD ["/usr/local/bin/start.sh"]

