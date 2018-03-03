#!/bin/sh
echo "\n========================================================"
echo "Starting routing build on `date`"
echo "========================================================"

OSMFILE=~/ltsanalyzer/update/rmoc.osm
OSRMEXTRACT="./node_modules/osrm/lib/binding/osrm-extract --verbosity WARNING -p ./node_modules/osrm/profiles/bicycle.lua"
OSRMCONTRACT="./node_modules/osrm/lib/binding/osrm-contract --verbosity WARNING"
MAPBOX=~/.local/bin/mapbox

cd ~/ottbike-maps-backend

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
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoienpwdGljaGthIiwiYSI6ImNqZWFwbXdsMDA4OWkzM2xhdjB0dmZqb2YifQ.sMrDpEWvtIM39hFZqkpLNQ"
#$MAPBOX upload zzptichka.53bf2frg data/level_1.json
#$MAPBOX upload zzptichka.771hbw7i data/level_2.json
#$MAPBOX upload zzptichka.5jgkszgd data/level_3.json
#$MAPBOX upload zzptichka.4ioiilcy data/level_4.json


echo "\nPreparing OSM extracts for each LTS...\n"
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

echo "\nDeleting OSM extracts...\n"

rm data/lts1/data.osm
rm data/lts2/data.osm
rm data/lts3/data.osm
rm data/lts4/data.osm

echo "Archiving directories...\n"
rm -R upload
mkdir upload
tar -zcf upload/lts1.tar.gz data/lts1
tar -zcf upload/lts2.tar.gz data/lts2
tar -zcf upload/lts3.tar.gz data/lts3
tar -zcf upload/lts4.tar.gz data/lts4

echo "============================================================="
echo "SUCCESS! Data in data/upload is archived and ready for upload"
echo "=============================================================\n"
