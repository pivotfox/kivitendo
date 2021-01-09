#!/bin/bash

# Create persistent volume directories
#  so you can populate them with existing data 
#  before starting the container stack

docker volume create --name $(basename ${PWD})_kivid_templ
docker volume create --name $(basename ${PWD})_kivid_config
docker volume create --name $(basename ${PWD})_kivid_documents
docker volume create --name $(basename ${PWD})_kivid_webdav
docker volume create --name $(basename ${PWD})_postgres
docker volume create --name $(basename ${PWD})_kivid_patches
docker volume create --name $(basename ${PWD})_kivid_cups

