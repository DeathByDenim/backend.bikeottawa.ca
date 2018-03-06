# backend.bikeottawa.ca
Set of scripts to generate and sync data files for maps.bikeottawa.ca

## Installation
Prerequisites: Node v6, Python v2.7
``` 
git clone https://github.com/zzptichka/backend.bikeottawa.ca
npm install
pip install --user mapboxcli
```

## Running
Builds OSRM data and syncs it to maps.bikeottawa.ca
```
./build.sh >> build.log
```
