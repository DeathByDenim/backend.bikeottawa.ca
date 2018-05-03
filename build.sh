#!/bin/sh
echo "\n========================================================"
echo "Starting routing build on `date`"
echo "========================================================"

OSMFILE=../ltsanalyzer/update/rmoc.osm
OSRMEXTRACT="./node_modules/osrm/lib/binding/osrm-extract --verbosity WARNING -p ./ottbike.lua"
OSRMCONTRACT="./node_modules/osrm/lib/binding/osrm-contract --verbosity WARNING"
#MAPBOX=mapbox                 #for Mac
MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoiYmlrZW90dGF3YSIsImEiOiJjamdqbmR2YmYwYzIyMzNtbmtidDQyeXM0In0.PNr-pb7EPHOcZ2vjikeVFQ"

cd ~/backend.bikeottawa.ca

if [ ! -e $OSMFILE ]; then
  echo "Error: Missing OSM file $OSMFILE"
  exit 1
fi

if ! [ -x "$(command -v $MAPBOX)" ]; then
  echo "Error: Missing mapbox-cli-py. Install using 'pip install --user mapboxcli'\n"
  exit 1
fi

if ! [ -x "$(command -v $OSRMCONTRACT)" ]; then
  echo "Error: Missing OSRM. Install using 'npm install osrm@5.15.1'\n"
  exit 1
fi

echo "\nCopying data files ... "

rm -R ./data
mkdir ./data
cp ../ltsanalyzer/levelfiles/level_1.json ./data
cp ../ltsanalyzer/levelfiles/level_2.json ./data
cp ../ltsanalyzer/levelfiles/level_3.json ./data
cp ../ltsanalyzer/levelfiles/level_4.json ./data

echo "\nUploading tilesets to Mapbox...\n"
$MAPBOX upload bikeottawa.7gev94ax data/level_1.json
$MAPBOX upload bikeottawa.2p4cgvm3 data/level_2.json
$MAPBOX upload bikeottawa.42dlr9v2 data/level_3.json
$MAPBOX upload bikeottawa.0ne8pnv3 data/level_4.json


echo "\nPreparing OSM extracts for each LTS...\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm use 6
mkdir data/lts1
mkdir data/lts2
mkdir data/lts3
mkdir data/lts4
echo "  Generating  data/lts1/data.osm"
node prepare-osm.js $OSMFILE 1 > data/lts1/data.osm
echo "  Generating  data/lts2/data.osm"
node prepare-osm.js $OSMFILE 2 > data/lts2/data.osm
echo "  Generating  data/lts3/data.osm"
node prepare-osm.js $OSMFILE 3 > data/lts3/data.osm
echo "  Generating  data/lts4/data.osm"
node prepare-osm.js $OSMFILE 4 > data/lts4/data.osm

echo "\nRunning OSRM scripts...\n"
if [ ! -e lib ]; then
  ln -s ./node_modules/osrm/profiles/lib
fi
echo "  Extracting  data/lts1/data.osrm"
$OSRMEXTRACT data/lts1/data.osm
echo "  Extracting  data/lts2/data.osrm"
$OSRMEXTRACT data/lts2/data.osm
echo "  Extracting  data/lts3/data.osrm"
$OSRMEXTRACT data/lts3/data.osm
echo "  Extracting  data/lts4/data.osrm"
$OSRMEXTRACT data/lts4/data.osm
echo "  Contracting  data/lts1/data.osrm"
$OSRMCONTRACT data/lts1/data.osrm
echo "  Contracting  data/lts2/data.osrm"
$OSRMCONTRACT data/lts2/data.osrm
echo "  Contracting  data/lts3/data.osrm"
$OSRMCONTRACT data/lts3/data.osrm
echo "  Contracting  data/lts4/data.osrm"
$OSRMCONTRACT data/lts4/data.osrm

echo "\nDeleting OSM extracts and LTS jsons...\n"

rm data/lts1/data.osm
rm data/lts2/data.osm
rm data/lts3/data.osm
rm data/lts4/data.osm
rm data/level_1.json
rm data/level_2.json
rm data/level_3.json
rm data/level_4.json




echo "Syncing data directory...\n"

rsync -rzaPq -e "ssh -i ~/.ssh/maps_id_rsa" data ubuntu@172.31.40.27:/home/ubuntu/maps.bikeottawa.ca-backend/

echo "============================================================="
echo "====== SUCCESS! OSRM files in data/ have been synced ========"
echo "=============================================================\n"
