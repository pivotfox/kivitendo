Welcome to kivitendo-compose
============================

kivitendo is a web-based application for customer addresses, products, warehouse management, quotations 
and commercial financial accounting for the German market.  

You can use it to do your office work both on the intranet and on the Internet. As an open source solution, 
it is the first choice if you want to add special forms, documents, tasks or functions that you want to use 
to meet your individual requirements.

To learn more about kivitendo please visit the maintainers page at [kivitendo.de](http://www.kivitendo.de/index.html)


# Table of Contents

- [Introduction](#introduction)
- [Changelog](Changelog.md)
- [Installation](#installation)
    - [General container settings](#general-container-settings)
    - [Credentials](#credentials)
- [kivitendo Quick Start](#kivitendo-quick-start)
- [Configuration](#configuration)
    - [Printing](#printing)
    - [WebDAV](#WebDAV)
- [Maintenance](#maintenance)
    - [Backup](#backup)
    - [Stopping and starting the container](#Stopping-and-starting-the-container)
    - [Upgrading](#upgrading)
- [Manage customizations](#manage-customization)

# Introduction

This repository contains the necessary tools to run a [kivitendo](http://www.kivitendo.de/index.html) 
stack on [Docker](https://www.docker.com/) using [Docker Compose](https://docs.docker.com/compose/).  

The stack and kivitendo image is based on debian (currently buster:slim) and will include Apache2 and all 
the necessary packages for kivitendo-erp and kivitendo-crm. For ease of use a CUPS server is included to 
get printers configured and running as well as a kivitendo task_server background worker.

A Postgresql database is part of this stack using the official container (e.g. the official postgresql build).

# Installation

In order to quickly run kivitendo on a machine running Docker and Docker Compose, follow these steps:  

-   Download and extract the [latest release](https://github.com/ptec-hjg/kivitendo-compose/releases/latest)  
	Alternatively, you can clone the repository:  
	```bash
git clone https://github.com/ptec-hjg/kivitendo-compose
cd kivitendo-compose
	```
-   Create a `.env` file by copying and adjusting env.example  
        `cp env.example .env`
-   Set passwords in the security section options of `.env` file  
-   Run `docker-compose up -d`  
    Access the web UI at `http://localhost` (or a different port, in case you edited the .env file).


To get access to the database files and other kivitendo directories later on you can link 
the docker persistent volumes to your working directory by running the script `create-symlinks.sh`.


There are a lot of parameters and options you can set within the `.env` file to suite your needs.
I will explain the most often used:

## General container settings

Variable | Description | Example
-------- | ----------- | -------
NAME_KIVI | Name of kivitendo container | kivid
NAME_DB | Name of postgres container | postgres2
RESTART_POLICY | Container restart policy | unless-stopped
TZ | Time zone of your kivitendo server  | Europe/Berlin
kivitendo_version | Kivitendo version to check out | release-3.5.6 or master
kivitendo_branch | branch for private customizations | customize
CRM | activate kivitendo-crm  | yes or no
HTTP_PORT | Exposed HTTP port | 80
CUPS_PORT | Exposed CUPS port | 631

These configuration options are already set and most of them don't need to be changed.  

Most probably you will set 'kivitendo_version' to the desired kivitendo version you want to work with.
If you don't change this parameter you will stick with the most current version of kivitendo at build 
time of the docker image, which likely might be an unstable version.

If you are not interested in using the kivitendo CRM package you should comment out the option 'CRM'.  

## Credentials

Variable | Description | Example
-------- | ----------- | -------
POSTGRES_PORT | Port to run postgres | 5432
PGDATA | Postgres data directory | /var/lib/postgresql/data/pgdata1
postgres_user | user name of postgres superuser | postgres
postgres_password | password of administrative superuser | postgres
kivitendo_user | database user for kivitendo | kivitendo
kivitendo_password | password of database user  | kivitendo
kivitendo_adminpassword | password for administrative login into kivitendo  | admin123
cups_user | administrative user of CUPS printing | admin
cups_password | password of CUPS administrator | admin
webdav_user | user name for WEBDAV access  | webdav
webdav_password | password for WEBDAV | webdav

The 'postgres_ ...' parameters tell our kivitendo how to connect to the postgres container and
what credentials to use.

The 'kivitendo_user/password' defines the kivitendo superuser needed to create and maintain your kivitendo databases.

The 'kivitendo_adminpassword' is used for the administrative login to manage users, groups, databases and printers
within kivitendo.

The 'cups_user/password' credentials are used to manage your printers via the cups GUI.


# kivitendo Quick Start

As your kivitendo containers started, you can go with this run-through to quickly get a working configuration.

The kivitendo container will be available by browsing to the ip of your docker host:
```bash
http://<ip_of_your_linux_box>
```

You will likely get an error message (Fehler 'Datenbank nicht erreichbar'), so you have to follow the link to
kivitendo's administrative interface. Use the in the `.env` file defined password 'admin123' (kivitendo_adminpassword) to login
 and perform the basic configuration:

- Create kivitendo database  
'Datenbankadministration' | 'Neue Datenbank anlegen' (IP, port, Datenbankbenutzer & Passwort do have defaults): 'Anmelden'  
'Tabellen anlegen', 'Weiter'

- Create user  
'Benutzer, Mandanten und Benutzergruppen' | 'Neuer Benutzer'
  Benutzer: 'user1', Passwort: 'user1', Name: 'User 1', 'Speichern'

- Create usergroup  
'Benutzer, Mandanten und Benutzergruppen' | 'Neuer Benutzergruppe'
  Name: 'Alle', check all heading checkboxes, move 'user1' into group, 'speichern'

- Create client database  
'Datenbankadministration' | 'Neue Datenbank anlegen'
  Datenbankanmeldung: 'anmelden' 
    'Neue Datenbank anlegen' 'db_mand1', SKR03, Soll-Versteuerung, Bestandsmethode, Bilanzierung, 'anlegen'

- Create client  
'Benutzer, Mandanten und Benutzergruppen' | 'Neuer Mandant'
  'Mandantname' 'Mand1', Standardmandant: j, Datenbankname: 'db_mand1', Zugriff: 'user1', 
    Gruppen: 'Alle'+'Vollzugriff', 'speichern'

- Go to the regular login screen  
'System' | 'Zum Benutzerlogin'

Now you can login as user 'user1' with the password 'user1' on  'Mand1'.

To let kivitendo create some important CRM database content, just load a screen from the crm:  
  CRM | Administration | Mandant

Congratulation, you have a running kivitendo docker container to play with.


# Configuration


## Printing

To configure a printer for your kivitendo system, you may use the CUPS GUI:

```bash
http://<ip_of_your_linux_box>:631
```

Configuring the CUPS system is beyond this guide, please take a look at
[Debian System Printing](https://wiki.debian.org/SystemPrinting).

When adding a printer you may have to enter administrative credentials which you had defined 
using the '-e "cups_user/password"' parameters.

It can be useful to 'Set Allowed Users' to 'root www-data print'.

If you want access your CUPS configuration from outside your kivitendo container (e.g. for backup reason) you can add
this line to your command with which you start the kivitendo container:

```bash
 -v kivid_cups:/etc/cups \
```

## WebDAV

You can access the kivitendo webdav directory via webdav (sic!) like this:

```bash
http://<ip_of_your_linux_box>/webdav
```

The default username and password are 'webdav' and 'webdav'.  
You can change the defaults to your own within the `.env` file.


# Maintenance


## Backup

You can backup your databases and kivitendo documents on your host with
the script `create_backup.sh`.  

Please edit the script to set the destination directory for your backups and define the databses 
you want to backup.  

To restore the databases from your backup you have to drop (delete) the currently running databases and
then feed postgres with the saved sql data.
```bash
docker exec -i postgres1 dropdb -U postgres kivitendo_auth
docker exec -i postgres1 psql -U postgres postgres  < <your_backup_path>/kivitendo_auth-20201122_16:20.sql
docker exec -i postgres1 dropdb -U postgres db_mand1
docker exec -i postgres1 psql -U postgres postgres  < <your_backup_path>/db_mand1-20201122_16:30.sql
```
(assuming that 'db_mand1' is your client database name)

## Stopping and starting the container stack

To stop the containers use:

```bash
$ docker-compose stop
```

To start the container stack again:

```bash
$ docker-compose up -d
```

If you want to remove the containers for a fresh start, maybe because you changed some settings
within the `.env` file, you will use this command:

```bash
$ docker-compose down
```


## Upgrading

Upgrading a kivitendo Docker container stack is actually a matter of stopping and deleting the containers
, downloading the most recent version from our github repository and starting the stack again. The containers will 
take care of updating the database structure to the newest version if necessary.

**IMPORTANT!** Do not delete any of the volumes, only the containers.


To upgrade to a newer releases, simply follow these steps.

- **Step 1**: Stop the currently running container

```bash
docker-compose down
```

- **Step 2**: Get the new Docker image version

```bash
git pull
```

- **Step 4**: Start the image and run the container

```bash
docker-compose up -d
```

Please use kivitendo's administrative login first to let kivitendo upgrade your databases.  


# Manage Customizations

A lot of people do not use the stock kivitendo but just pull it from the official repository and add their
own customizations, without pushing back to the main repository.

How do you manage those customizations with this docker stack, and how do you apply your changes
to the next version of the image?

For this we use the git patch commands, creating appropriate patch files for all your changes, and applying those 
patches when a new version of the docker image is run.

To define the name of your own branch of kivitendo by setting the variable "kivitendo_branch=customize"
within the `.env` file before creating the container.  

To do your customization you would typically work within your running container. To jump into it use:

```bash
docker-compose exec kivi bash
```

Kivitendo is located as usual at /var/www/kivitendo-erp (the crm is at /var/www/kivitendo-crm), and you are
already within your working branch as defined above ('customize' as default).  

When all your changes are done, you have to use this command to create patch files:

```bash
git commit -a -m "<your descriptive comment>"
git format-patch master -o /var/www/patches/erp
```

Git will create patch files reflecting your changes into the named directory.

Type `exit` to leave the container.  

And that's it.  
The next time you pull and start a new version of this docker image, the
container will automagically apply your patches to kivitendo.

To create patch files for the kivitendo-crm please use '/var/www/patches/crm' as output directory for
the above 'git format-patch' command.

You should check the appropriate log files generated within the patch directories to be sure that your
patches are proccessed successfully.  
Any conflicts have to be resolved by you.

