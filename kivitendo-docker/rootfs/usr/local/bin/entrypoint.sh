#!/bin/sh
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

die() {
    local message=${1-Died}
    echo "${BASH_SOURCE[1]}: line ${BASH_LINENO[0]}: ${FUNCNAME[1]}: $message." >&2
    exit 1
}

echo "waiting for postgres container to startup ..."
until psql "host=$postgres_host user=$postgres_user password=$postgres_password" -c '\q'; do
	>&2 echo "Postgres is not yet available - waiting ..."
	sleep 30
done

# first time run ?
if [ -f /tmp/container_first ]; then
  echo "Kivitendo container first run"

  rm /tmp/container_first

  # checkout standard kivitendo version
  echo "  checking out version ${kivitendo_version} ..."
  cd /var/www/kivitendo-erp
  git checkout ${kivitendo_version} || die "error on checking out erp"
  cd /var/www/kivitendo-crm
  git checkout ${kivitendo_crm_version} || die "error on checking out crm"
  cd /var/www/kivitendo-erp

  # activate crm module
  if [ "$CRM" = 'yes' -o "$CRM" = 'YES'  -o "$CRM" = '1' ]; then
    echo "  activating CRM modules ..."
    cd /var/www/kivitendo-erp
    ln -s ../kivitendo-crm/ crm
    # crm modifications
    cd /var/www/
    sed -i '$adocument.write("<script type='text/javascript' src='crm/js/ERPplugins.js'></script>");' kivitendo-erp/js/kivi.js
    sed -i '/var baseUrl/a baseUrl = getUrl \.protocol + "\/\/" + getUrl\.host + "\/";' kivitendo-crm/js/tools.js
    #
    cd /var/www/kivitendo-erp/menus/user && ln -s ../../../kivitendo-crm/menu/10-crm-menu.yaml 10-crm-menu.yaml
    cd /var/www/kivitendo-erp/sql/Pg-upgrade2-auth && ln -s  ../../../kivitendo-crm/update/add_crm_master_rights.sql add_crm_master_rights.sql
    cd /var/www/kivitendo-erp/locale/de && mkdir -p more && cd more && ln -s ../../../../kivitendo-crm/menu/t8e/menu.de crm-menu.de && ln -s ../../../../kivitendo-crm/menu/t8e/menu-admin.de crm-menu-admin.de
  else
    echo "  skip activating CRM modules"
  fi

  echo "  checking out custom git branch ${kivitendo_branch} & apply patches ..."

  cd /var/www/kivitendo-erp
  git checkout -b ${kivitendo_branch} || die "error on checking out erp branch"
  for file in /var/www/patches/erp/*.patch
  do
    if [ -f $file ]; then echo "  patching file $file" && git am $file >> /var/www/patches/erp.log || true; fi
  done

  cd /var/www/kivitendo-crm || die "error on checking out crm branch"
  git checkout -b ${kivitendo_crm_branch} || die "error on checking out crm branch"
  for file in /var/www/patches/crm/*.patch
  do
    if [ -f $file ]; then echo "  patching file $file" && git am $file >> /var/www/patches/crm.log || true; fi
  done

  echo "  setting mailer configuration ..."
  # exim4 can't bind to ::1, so update configuration
  sed -i "s/dc_local_interfaces.*/dc_local_interfaces='127.0.0.1 ; '/" /etc/exim4/update-exim4.conf.conf
  update-exim4.conf
  echo "root: ${root_alias}" >> /etc/aliases
  newaliases

  echo "  setting CUPS configuration ..."
  # Add printer administrator and disable sudo password checking
  useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/${cups_user} \
  --shell=/bin/bash \
  --password=$(mkpasswd ${cups_password}) \
  ${cups_user} \
  && sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

  # Don't switch to https
  echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

  # Configure CUPS to be reachable from outside
  /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)

  echo "  setting Apache fcgid configuration ..."
  sed -i '/FcgidConnectTimeout.*/a \
    FcgidConnectTimeout 270 \
    FcgidIOTimeout 7200 \
#    FcgidProcessLifeTime 7200 \
#    FcgidMaxRequestLen 1000000000 \
#    IdleTimeout 280 \
#    BusyTimeout 300 \
#    ProcessLifeTime 7200 \
#    IPCConnectTimeout 320 \
#    IPCCommTimeout 7200 ' /etc/apache2/mods-available/fcgid.conf

  echo "First time configuration is done!"
else
  echo "Kivitendo container appears to be initialized already"
fi

if [ ! -f /var/www/kivitendo-erp/config/kivitendo.conf ]; then
  echo "Kivitendo configuration directory is empty, so start initialization"


  echo "... creating kivitendo.conf"
  cp /var/www/kivitendo-erp/config/kivitendo.conf.default /var/www/kivitendo-erp/config/kivitendo.conf

  sed -i "s/admin_password.*/admin_password = $kivitendo_adminpassword/" /var/www/kivitendo-erp/config/kivitendo.conf

  sed -i "/^# users/,/^\[authentication/ s/localhost/$postgres_host/" /var/www/kivitendo-erp/config/kivitendo.conf
  sed -i "/^# users/,/^\[authentication/ s/user     =.*/user     = $kivitendo_user/" /var/www/kivitendo-erp/config/kivitendo.conf
  sed -i "/^# users/,/^\[authentication/ s/password =.*/password = $kivitendo_password/" /var/www/kivitendo-erp/config/kivitendo.conf

  sed -i "/testing/,/^\[devel/ s/localhost/$postgres_host/" /var/www/kivitendo-erp/config/kivitendo.conf
  sed -i "/testing/,/^\[devel/ s/^user               =.*/user               = $kivitendo_user/" /var/www/kivitendo-erp/config/kivitendo.conf
  sed -i "/testing/,/^\[devel/ s/^password           =.*/password           = $kivitendo_password/" /var/www/kivitendo-erp/config/kivitendo.conf
  sed -i "/testing/,/^\[devel/ s/^superuser_user     =.*/superuser_user     = $postgres_user/" /var/www/kivitendo-erp/config/kivitendo.conf
  sed -i "/testing/,/^\[devel/ s/^superuser_password =.*/superuser_password = $postgres_password/" /var/www/kivitendo-erp/config/kivitendo.conf

  sed -i "s%^# document_path =.*%document_path = /var/www/kivitendo-erp/kivi_documents%" /var/www/kivitendo-erp/config/kivitendo.conf


  echo "... creating database user & extensions"
  # create user & extension
  psql "host=$postgres_host user=$postgres_user password=$postgres_password" --command "CREATE EXTENSION IF NOT EXISTS plpgsql;"  >> /var/log/postgres_config.log
  psql "host=$postgres_host user=$postgres_user password=$postgres_password" --command "CREATE USER ${kivitendo_user} WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS  ENCRYPTED PASSWORD '${kivitendo_password}';" >> /var/log/postgres_config.log
  #psql "host=$postgres_host user=$postgres_user password=$postgres_password" --command "CREATE USER ${kivitendo_user} WITH CREATEDB CREATEROLE CREATEUSER  ENCRYPTED PASSWORD '${kivitendo_password}';" >> /var/log/postgres_config.log

else
  echo "Kivitendo configuration directory appears to contain a valid configuration; Skipping initialization"
fi


if ! cat /var/www/kivitendo-erp/scripts/task_server.pl | grep -q "foreground"; then
  echo "patching task_server.pl"
  sed -i "/progname   => 'kivitendo-background-jobs'.*/a \
	foreground    => 1,\
" /var/www/kivitendo-erp/scripts/task_server.pl
fi

if [ ! -f /var/www/kivitendo-erp/config/webdav_passwd ]; then
  echo "creating webdav credentials"
  htpasswd -b -c /var/www/kivitendo-erp/config/webdav_passwd $webdav_user $webdav_password
  chown www-data:www-data /var/www/kivitendo-erp/config/webdav_passwd
  chmod 770 /var/www/kivitendo-erp/config/webdav_passwd
fi

if [ ! -d /var/www/kivitendo-erp/templates/$KIVITENDO_TEMPLATE ]; then
    echo "... creating print template directory [$KIVITENDO_TEMPLATE]"
    mkdir -p /var/www/kivitendo-erp/templates/$KIVITENDO_TEMPLATE
fi
if [ -n "$(find "/var/www/kivitendo-erp/templates/$KIVITENDO_TEMPLATE" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
    echo "... filling print template directory [$KIVITENDO_TEMPLATE]"
    cp -a /var/www/kivitendo-erp/templates/print/RB/* /var/www/kivitendo-erp/templates/$KIVITENDO_TEMPLATE
    chown -R www-data:www-data /var/www/kivitendo-erp/templates/$KIVITENDO_TEMPLATE
else
    echo "... print template directory [$KIVITENDO_TEMPLATE] already populated"
fi

#Check Kivitendo installation
echo "... checking kivitendo configuration"
cd /var/www/kivitendo-erp/ && perl /var/www/kivitendo-erp/scripts/installation_check.pl

echo "now executing $@"

exec "$@"
