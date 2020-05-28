#!/bin/sh
echo "========================================================"
echo "Starting winter build on `date`"
echo "========================================================"

NAME=winter
QUERY_FILE=./osm/$NAME.query
OSM_FILE=./osm/$NAME.osm
JSON_FILE=./osm/$NAME.json
JSON_OLD_FILE=./osm/$NAME-old.json


#MAPBOX=mapbox                 #for Mac
MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoiYmlrZW90dGF3YSIsImEiOiJja2FxY3I0YjEwODZhMnRucmVsMWc1emF2In0.7vkG51uoW7yMkbr6ZrGc1Q"
OSMTOGEOJSON=/usr/local/bin/osmtogeojson
#OSMTOGEOJSON=osmtogeojson
GEOJSONPICK=/usr/local/bin/geojson-pick
#GEOJSONPICK=geojson-pick
PICKTAGS="winter_service id"

cd ~/backend.bikeottawa.ca

echo "Processing and uploading winter pathways data ..."

if [ ! -e $QUERY_FILE ]; then
  echo "Error: Missing winter pathways query file $QUERY_FILE"
  exit 1
fi

rm $OSM_FILE
mv $JSON_FILE $JSON_OLD_FILE

wget -nv -O $OSM_FILE --post-file=$QUERY_FILE "http://overpass-api.de/api/interpreter"

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running wget."
  exit 1
fi

$OSMTOGEOJSON -m $OSM_FILE | $GEOJSONPICK $PICKTAGS > $JSON_FILE

if [ $? -ne 0 ]; then
  echo "Error: There was a problem running osmtogeojson."
  exit 1
fi

if cmp -s $JSON_FILE $JSON_OLD_FILE; then
    echo 'No changes'
    exit 0
fi

$MAPBOX upload bikeottawa.0lwwjb4e $JSON_FILE
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload winter pathways tileset to Mapbox."
  exit 1
fi
