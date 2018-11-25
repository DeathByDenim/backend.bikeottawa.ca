#!/bin/sh
echo "========================================================"
echo "Starting winter build on `date`"
echo "========================================================"

WINTER_QUERY=./osm/winter.query
WINTER_OSM=./osm/winter.osm
WINTER_JSON=./osm/winter.json

#MAPBOX=mapbox                 #for Mac
MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoiYmlrZW90dGF3YSIsImEiOiJjamdqbmR2YmYwYzIyMzNtbmtidDQyeXM0In0.PNr-pb7EPHOcZ2vjikeVFQ"
OSMTOGEOJSON=/usr/local/bin/osmtogeojson
#OSMTOGEOJSON=osmtogeojson
GEOJSONPICK=/usr/local/bin/geojson-pick
#GEOJSONPICK=geojson-pick
PICKTAGS="winter_service winter_service:quality surface width id"

cd ~/backend.bikeottawa.ca

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

$OSMTOGEOJSON -m $WINTER_OSM | $GEOJSONPICK $PICKTAGS > $WINTER_JSON

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running osmtogeojson."
  exit 1
fi

$MAPBOX upload bikeottawa.03jqtlpj $WINTER_JSON
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload desire lines tileset to Mapbox."
  exit 1
fi
