#!/bin/bash

#Ensure data dump file is in our directory
if [ ! -f geonames.tar ]; then
  aws s3 cp s3://bsve-integration/geonames.tar ./geonames.tar
fi

#Build and spin up our mongodb
./mongodb.sh

#Import the geonames dataset
mv -v ./geonames.tar /var/log
cd /var/log/ && tar -xf geonames.tar &&\ 
docker exec -t mongodb mongorestore --db geonames /var/log/geonames

#Ensure we have a copy of the grits image
if [[ ! -f grits-provisioned.tar.gz && ! -f grits-provisioned.tar ]]; then
  aws s3 cp s3://bsve-integration/grits-provisioned.tar.gz ./grits-provisioned.tar.gz
  gzip -d grits-provisioned.tar.gz
fi

docker load < grits-provisioned.tar

#Get and configure docker compose file for grits
export LOCAL_IP=$(ifconfig eth0|grep "inet addr"|awk -F":" '{print $2}'|awk '{print $1}')
wget https://raw.githubusercontent.com/ecohealthalliance/grits-deploy-ansible/master/compose.yml --output-document=grits.yml
sed -i "s/172.30.2.123/$LOCAL_IP/" grits.yml
sed -i "s/image: grits/image: grits-provisioned/" grits.yml

docker-compose -f grits.yml up -d
