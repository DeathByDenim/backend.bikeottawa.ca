#!/bin/bash
echo "\n========================================================"
echo "Starting routing build on `date`"
echo "========================================================"

cd ~/backend.bikeottawa.ca

OSMFILE=../ltsanalyzer/update/rmoc.osm
OSRMEXTRACT="sudo docker run -t -v $(pwd)/data:/data osrm/osrm-backend osrm-extract --verbosity WARNING -p /data/bicycle-orig.lua"
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

rm -fR ./data
mkdir ./data
cp ./bicycle-orig.lua ./data
cp ../ltsanalyzer/levelfiles/level_*.json ./data


echo "\nPreparing OSM extracts for each LTS...\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm use 6

for i in {1..4}
do
  mkdir data/lts$i
  echo "  Generating  lts$i/data.osm"
  node prepare-osm.js $OSMFILE $i > data/lts$i/data.osm
  if [ $? -ne 0 ]; then
    echo "Error: Failed to generate LTS-$i OSM."
    exit 1
  fi
done

echo "\nRunning OSRM scripts...\n"
cd data

for i in {1..4}
do
  echo "  Extracting  lts$i/data.osrm"
  $OSRMEXTRACT /data/lts$i/data.osm
  if [ $? -ne 0 ]; then
    echo "Error: Failed to extract."
    exit 1
  fi
done

for i in {1..4}
do
  echo "  Contracting  lts$i/data.osrm"
  $OSRMCONTRACT /data/lts$i/data.osrm
  if [ $? -ne 0 ]; then
    echo "Error: Failed to contract."
    exit 1
  fi
  rm lts$i/data.osm
  rm level_$i.json
done

exit 0

echo "Syncing data directory...\n"

cd ..
rsync -rzaPq -e "ssh -i ~/.ssh/maps_id_rsa" data ubuntu@172.31.40.27:/home/ubuntu/maps.bikeottawa.ca-backend/
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload generated files to Maps server."
  exit 1
fi
echo "============================================================="
echo "====== SUCCESS! OSRM files in data/ have been synced ========"
echo "=============================================================\n"
