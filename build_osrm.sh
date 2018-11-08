#!/bin/sh
echo "\n========================================================"
echo "Starting routing build on `date`"
echo "========================================================"

cd ~/backend.bikeottawa.ca

OSMFILE=../ltsanalyzer/update/rmoc.osm
OSRMEXTRACT="sudo docker run -t -v $(pwd)/data:/data osrm/osrm-backend osrm-extract -p /data/bicycle-orig.lua"
OSRMCONTRACT="sudo docker run -t -v $(pwd)/data:/data osrm/osrm-backend osrm-contract --verbosity WARNING"


if [ ! -e $OSMFILE ]; then
  echo "Error: Missing OSM file $OSMFILE"
  exit 1
fi

if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Missing docker. Install docker and try again'\n"
  exit 1
fi

echo "\nCopying data files ... "

rm -R ./data
mkdir ./data
cp ./bicycle-orig.lua ./data
cp ../ltsanalyzer/levelfiles/level_*.json ./data


echo "\nPreparing OSM extracts for each LTS...\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm use 6
mkdir data/lts1
mkdir data/lts2
mkdir data/lts3
mkdir data/lts4

echo "  Generating  lts1/data.osm"
node prepare-osm.js $OSMFILE 1 > data/lts1/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate LTS-1 OSM."
  exit 1
fi
echo "  Generating  lts2/data.osm"
node prepare-osm.js $OSMFILE 2 > data/lts2/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate LTS-2 OSM."
  exit 1
fi
echo "  Generating  lts3/data.osm"
node prepare-osm.js $OSMFILE 3 > data/lts3/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate LTS-3 OSM."
  exit 1
fi
echo "  Generating  lts4/data.osm"
node prepare-osm.js $OSMFILE 1 > data/lts4/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate LTS-4 OSM."
  exit 1
fi

echo "\nRunning OSRM scripts...\n"
cd data
echo "  Extracting  lts1/data.osrm"
  $OSRMEXTRACT /data/lts1/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to extract."
  exit 1
fi
echo "  Extracting  lts2/data.osrm"
  $OSRMEXTRACT /data/lts2/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to extract."
  exit 1
fi
echo "  Extracting  lts3/data.osrm"
  $OSRMEXTRACT /data/lts3/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to extract."
  exit 1
fi
echo "  Extracting  lts4/data.osrm"
  $OSRMEXTRACT /data/lts4/data.osm
if [ $? -ne 0 ]; then
  echo "Error: Failed to extract."
  exit 1
fi

echo "  Contracting  lts1/data.osrm"
$OSRMCONTRACT /data/lts1/data.osrm
if [ $? -ne 0 ]; then
  echo "Error: Failed to contract."
  exit 1
fi
echo "  Contracting  lts2/data.osrm"
$OSRMCONTRACT /data/lts2/data.osrm
if [ $? -ne 0 ]; then
  echo "Error: Failed to contract."
  exit 1
fi
echo "  Contracting  lts3/data.osrm"
$OSRMCONTRACT /data/lts3/data.osrm
if [ $? -ne 0 ]; then
  echo "Error: Failed to contract."
  exit 1
fi
echo "  Contracting  lts4/data.osrm"
$OSRMCONTRACT /data/lts4/data.osrm
if [ $? -ne 0 ]; then
  echo "Error: Failed to contract."
  exit 1
fi


echo "\nDeleting OSM extracts and LTS jsons...\n"
cd ..
rm data/lts1/data.osm
rm data/lts2/data.osm
rm data/lts3/data.osm
rm data/lts4/data.osm
rm data/level_*.json

exit 0

echo "Syncing data directory...\n"

rsync -rzaPq -e "ssh -i ~/.ssh/maps_id_rsa" data ubuntu@172.31.40.27:/home/ubuntu/maps.bikeottawa.ca-backend/
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload generated files to Maps server."
  exit 1
fi
echo "============================================================="
echo "====== SUCCESS! OSRM files in data/ have been synced ========"
echo "=============================================================\n"
