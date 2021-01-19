#!/bin/bash

# Create links from Dockers persistent volumes directories to current working dir
# to ease access

VOLUMES=/var/lib/docker/volumes

ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_templ/_data ${PWD}/kivid_templ
ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_config/_data ${PWD}/kivid_config
ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_documents/_data ${PWD}/kivid_documents
ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_webdav/_data ${PWD}/kivid_webdav
ln -sn ${VOLUMES}/$(basename ${PWD})_postgres/_data ${PWD}/postgres2
ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_patches/_data ${PWD}/kivid_patches
ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_cups/_data ${PWD}/kivid_cups
ln -sn ${VOLUMES}/$(basename ${PWD})_kivid_exim/_data ${PWD}/kivid_exim
