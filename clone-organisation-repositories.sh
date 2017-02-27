#!/bin/bash

####
## CLONE-ORGANISATION-REPOSITORIES.SH
## call with "call-organisation-repositories.sh GITHUBTOKEN ORGANISATION S3BUCKETNAME S3BUCKETPREFIX"
## This script will do the following:
## 1. Create a temporary directory in /tmp/ to store repositories
## 2. Pull a list of all GitHub repositories for a given organisation
## 3. `git clone` that list onto disk (using the GitHub personal access token
## 4. tar repositories up into one file (named with the date)
## 5. Upload tar file to S3
## 6. Delete temporary directory created in #1
####


####
## VARIABLES
####

TOKEN=$1
ORGANISATION=$2
BUCKETNAME=$3
BUCKETPREFIX=$4

TEMPDIRECTORY=/tmp/repositories
DATE=`date +%Y%m%d`

####
## MAKING TEMP DIRECTORY
####

rm -rf "${TEMPDIRECTORY}"
mkdir "${TEMPDIRECTORY}"
cd "${TEMPDIRECTORY}"

####
## FINDING AND CLONING ALL REPOS
####

for x in $(echo "${ORGANISATION}" | sed "s/,/ /g")
do
mkdir "${TEMPDIRECTORY}"/"${x}"
cd "${TEMPDIRECTORY}"/"${x}"

for i in `curl -u "${TOKEN}":x-oauth-basic -s "https://api.github.com/orgs/"${x}"/repos" | grep clone_url | cut -d ':' -f 2-3|tr -d '",' | cut -c10- `;
do
git clone https://"${TOKEN}":x-oauth-basic@"${i}";
done

####
## ZIPPING UP REPOS
####

tar cf "${x}"-repositories-"${DATE}".tar.bz2 *

####
## UPLOADING TAR FILE TO S3
####

aws s3 cp "${x}"-repositories-"${DATE}".tar.bz2 s3://"${BUCKETNAME}"/"${BUCKETPREFIX}"/"${x}"/

done

####
## CLEANING UP
####

rm -rf "${TEMPDIRECTORY}"
