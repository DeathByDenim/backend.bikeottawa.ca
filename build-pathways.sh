#!/bin/sh
echo "========================================================"
echo "Starting pathways build on `date`"
echo "========================================================"

PATHWAYS_QUERY=./osm/pathways.query
PATHWAYS_OSM=./osm/pathways.osm
PATHWAYS_JSON=./osm/pathways.json

MAPBOX=mapbox                 #for Mac
#MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoiYmlrZW90dGF3YSIsImEiOiJjamdqbmR2YmYwYzIyMzNtbmtidDQyeXM0In0.PNr-pb7EPHOcZ2vjikeVFQ"
#OSMTOGEOJSON=/usr/local/bin/osmtogeojson
OSMTOGEOJSON=osmtogeojson
#GEOJSONPICK=/usr/local/bin/geojson-pick
GEOJSONPICK=geojson-pick
PATHWAYS_PICKTAGS="winter_service surface width smoothness lit id"

cd ~/backend.bikeottawa.ca

echo "Processing and uploading winter pathways data ..."

if [ ! -e $PATHWAYS_QUERY ]; then
  echo "Error: Missing pathways query file $PATHWAYS_QUERY"
  exit 1
fi

rm $PATHWAYS_OSM
rm $PATHWAYS_JSON

wget -nv -O $PATHWAYS_OSM --post-file=$PATHWAYS_QUERY "http://overpass-api.de/api/interpreter"

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running wget."
  exit 1
fi

$OSMTOGEOJSON -m $PATHWAYS_OSM | $GEOJSONPICK $PATHWAYS_PICKTAGS > $PATHWAYS_JSON

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running osmtogeojson."
  exit 1
fi

$MAPBOX upload bikeottawa.6wnvt0cx $PATHWAYS_JSON
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload desire lines tileset to Mapbox."
  exit 1
fi
