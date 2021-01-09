#!/bin/bash

# Create a backup of databases and documents

# Include .env file
. ${PWD}/.env

DATE=`date -I`
BACKUP_DIR=${PWD}/backup
DEST=${BACKUP_DIR}/backup_${DATE}

# Name of database you created from the kivitendo administration area
DB_MAND=db_mand1

# Path to docker volumes on this host
VOLUMES=/var/lib/docker/volumes


# create destination directories
mkdir -p ${DEST}

# remove all but the most recent 15 backups
#find ${BACKUP_DIR}/* -maxdepth 1 -type d | sort -r |  awk 'NR>15' | xargs -L1 rm -rf


# backup databases
docker exec -i ${NAME_DB} pg_dump -U ${postgres_user} -C  kivitendo_auth > ${DEST}/kivitendo_auth-`date +%Y%m%d_%R`.sql
docker exec -i ${NAME_DB} pg_dump -U ${postgres_user} -C  ${DB_MAND} > ${DEST}/${DB_MAND}-`date +%Y%m%d_%R`.sql
# backup documents
tar cfz ${DEST}/kivi-data-`date +%Y%m%d_%R`.tar.gz \
${VOLUMES}/$(basename ${PWD})_kivid_config \
${VOLUMES}/$(basename ${PWD})_kivid_cups \
${VOLUMES}/$(basename ${PWD})_kivid_templ \
${VOLUMES}/$(basename ${PWD})_kivid_documents \
${VOLUMES}/$(basename ${PWD})_kivid_webdav \
${VOLUMES}/$(basename ${PWD})_kivid_patches \
${VOLUMES}/$(basename ${PWD})_postgres 

