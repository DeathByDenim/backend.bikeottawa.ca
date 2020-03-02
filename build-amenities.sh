#!/bin/sh
echo "========================================================"
echo "Starting amenities build on `date`"
echo "========================================================"

NAME=amenities
QUERY_FILE=./osm/$NAME.query
OSM_FILE=./osm/$NAME.osm
JSON_FILE=./osm/$NAME.json
JSON_OLD_FILE=./osm/$NAME-old.json

#MAPBOX=mapbox                 #for Mac
MAPBOX=~/.local/bin/mapbox   #for Linux
export MAPBOX_ACCESS_TOKEN="sk.eyJ1IjoiYmlrZW90dGF3YSIsImEiOiJjamdqbmR2YmYwYzIyMzNtbmtidDQyeXM0In0.PNr-pb7EPHOcZ2vjikeVFQ"
OSMTOGEOJSON=/usr/local/bin/osmtogeojson
#OSMTOGEOJSON=osmtogeojson
GEOJSONPICK=/usr/local/bin/geojson-pick
#GEOJSONPICK=geojson-pick
PICKTAGS="id amenity leisure playground tourism shop"

cd ~/backend.bikeottawa.ca

echo "Processing and uploading amenities data ..."

if [ ! -e $QUERY_FILE ]; then
  echo "Error: Missing amenities query file $QUERY_FILE"
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

$MAPBOX upload bikeottawa.6e5700mn $JSON_FILE
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload amenities tileset to Mapbox."
  exit 1
fi
