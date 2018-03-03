#!/bin/sh
echo "========================================================"
echo "Starting routing update at `date`"
echo "========================================================"

OSMFILE=data/ottawa.osm
OSRMEXTRACT=./node_modules/osrm/lib/binding/osrm-extract
OSRMCONTRACT=./node_modules/osrm/lib/binding/osrm-contract
OSRMPROFILE=./node_modules/osrm/profiles/bicycle.lua

if [ ! -e $OSMFILE ]; then
  echo "Error: Missing OSM file $OSMFILE"
  exit 1
fi

if ! [ -x "$(command -v mapbox)" ]; then
  echo "Error: Missing mapbox-cli-py. Install using 'pip install --user mapboxcli'\n"
  exit 1
fi

if ! [ -x "$(command -v $OSRMCONTRACT)" ]; then
  echo "Error: Missing OSRM. Install using 'npm install osrm@5.15.1'\n"
  exit 1
fi

echo "Uploading tilesets...\n"
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoienpwdGljaGthIiwiYSI6ImNqZWFwbXdsMDA4OWkzM2xhdjB0dmZqb2YifQ.sMrDpEWvtIM39hFZqkpLNQ"
mapbox upload zzptichka.53bf2frg data/level_1.json
mapbox upload zzptichka.771hbw7i data/level_2.json
mapbox upload zzptichka.5jgkszgd data/level_3.json
mapbox upload zzptichka.4ioiilcy data/level_4.json


echo "Prepping OSM extracts for each LTS...\n"
mkdir data/lts1
mkdir data/lts2
mkdir data/lts3
mkdir data/lts4
node prepare-osm.js $OSMFILE 1 > data/lts1/data.osm
node prepare-osm.js $OSMFILE 2 > data/lts2/data.osm
node prepare-osm.js $OSMFILE 3 > data/lts3/data.osm
node prepare-osm.js $OSMFILE 4 > data/lts4/data.osm

echo "Running OSRM scripts...\n"

$OSRMEXTRACT data/lts1/data.osm -p $OSRMPROFILE
$OSRMEXTRACT data/lts2/data.osm -p $OSRMPROFILE
$OSRMEXTRACT data/lts3/data.osm -p $OSRMPROFILE
$OSRMEXTRACT data/lts4/data.osm -p $OSRMPROFILE
$OSRMCONTRACT data/lts1/data.osrm
$OSRMCONTRACT data/lts2/data.osrm
$OSRMCONTRACT data/lts3/data.osrm
$OSRMCONTRACT data/lts4/data.osrm


echo "========================================================"
echo "SUCCESS!"
echo "========================================================"
