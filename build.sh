#!/bin/bash
echo "========================================================"
echo "Starting routing build on `date`"
echo "========================================================"

OSRMPROFILE="ottbike2.lua"  #new version based on api ver 4
OSMFILE=../ltsanalyzer/update/rmoc.osm
OSRMEXTRACT="./node_modules/osrm/lib/binding/osrm-extract --verbosity WARNING"
OSRMCONTRACT="./node_modules/osrm/lib/binding/osrm-contract --verbosity WARNING"
DESIRE_QUERY=./desire/desire.query
DESIRE_OSM=./desire/desire.osm
DESIRE_JSON=./desire/desire.json
WINTER_QUERY=./winter/winter.query
WINTER_OSM=./winter/winter.osm
WINTER_JSON=./winter/winter.json

#MAPBOX=mapbox                 #for Mac
MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoiYmlrZW90dGF3YSIsImEiOiJjamdqbmR2YmYwYzIyMzNtbmtidDQyeXM0In0.PNr-pb7EPHOcZ2vjikeVFQ"

if [ ! -e $OSMFILE ]; then
  echo "Error: Missing OSM file $OSMFILE"
  exit 1
fi

if [ ! -e $DESIRE_QUERY ]; then
  echo "Error: Missing query file $DESIRE_QUERY"
  exit 1
fi

echo "Processing and uploading desire lines data ..."
rm $DESIRE_OSM
rm $DESIRE_JSON

wget -nv -O $DESIRE_OSM --post-file=$DESIRE_QUERY "http://overpass-api.de/api/interpreter"
if [ $? -ne 0 ]; then
  echo "Error: There was a problem downloading desire lines from Overpass."
  exit 1
fi

/usr/local/bin/osmtogeojson -m $DESIRE_OSM > $DESIRE_JSON
if [ $? -ne 0 ]; then
  echo "Error: There was a problem running osmtogeojson on desire lines file."
  exit 1
fi

$MAPBOX upload bikeottawa.4hnbbuhd $DESIRE_JSON
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload desire line tileset to Mapbox."
  exit 1
fi

echo "Success!"

echo "Processing and uploading winter pathways data ..."

if [ ! -e $WINTER_QUERY ]; then
  echo "Error: Missing winter pathways query file $WINTER_QUERY"
  exit 1
fi

rm $WINTER_OSM
rm $WINTER_JSON

wget -nv -O $WINTER_OSM --post-file=$WINTER_QUERY "http://overpass-api.de/api/interpreter"

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running wget."
  exit 1
fi

/usr/local/bin/osmtogeojson -m $WINTER_OSM > $WINTER_JSON

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running osmtogeojson."
  exit 1
fi

$MAPBOX upload bikeottawa.03jqtlpj $WINTER_JSON
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload desire lines tileset to Mapbox."
  exit 1
fi

echo "Success!"

echo "Copying LTS and OSM data files ... "

rm -fR data
mkdir data
cp ../ltsanalyzer/levelfiles/level_*.json data

echo "Uploading tilesets to Mapbox..."
$MAPBOX upload bikeottawa.7gev94ax data/level_1.json
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload tilesets to Mapbox."
  exit 1
fi
$MAPBOX upload bikeottawa.2p4cgvm3 data/level_2.json
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload tilesets to Mapbox."
  exit 1
fi
$MAPBOX upload bikeottawa.42dlr9v2 data/level_3.json
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload tilesets to Mapbox."
  exit 1
fi
$MAPBOX upload bikeottawa.0ne8pnv3 data/level_4.json
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload tilesets to Mapbox."
  exit 1
fi


echo "Preparing OSM extracts for each LTS..."
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

echo "Running OSRM scripts..."

for i in {1..4}
do
  echo "  Extracting  lts$i/data.osrm"
  $OSRMEXTRACT -p $OSRMPROFILE data/lts$i/data.osm
  if [ $? -ne 0 ]; then
    echo "Error: Failed to extract."
    exit 1
  fi
done

for i in {1..4}
do
  echo "  Contracting  lts$i/data.osrm"
  $OSRMCONTRACT data/lts$i/data.osrm
  if [ $? -ne 0 ]; then
    echo "Error: Failed to contract."
    exit 1
  fi
  rm data/lts$i/data.osm
  rm data/level_$i.json
done

echo "Processing walking profile..."
mkdir data/foot
cp $OSMFILE data/foot/data.osm
echo "  Extracting  foot/data.osrm"
$OSRMEXTRACT -p foot.lua data/foot/data.osm
echo "  Contracting  foot/data.osrm"
$OSRMCONTRACT data/foot/data.osrm
rm data/foot/data.osm


echo "Syncing data directory..."

rsync -rzaPq -e "ssh -i ~/.ssh/maps_id_rsa" data ubuntu@172.31.40.27:/home/ubuntu/maps.bikeottawa.ca-backend/
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload generated files to Maps Frontend server."
  exit 1
fi
echo "============================================================="
echo "====== SUCCESS! OSRM files in data/ have been synced ========"
echo "============================================================="
