const reader = require('geojson-writer').reader
const writer = require('geojson-writer').writer
const fs = require('fs');
const args = require('minimist')(process.argv.slice(2));
let inPath;

if (args.help) {
  const usage = `
  Usage: node calc-stats.js [geojson_file]

  where [geojson_file] - path to calculate stats
  `;
  process.stdout.write(`${usage}\n`);
  process.exit(0);
}

try {
  inPath = args._[0]
  fs.accessSync(inPath, fs.F_OK)
} catch (error) {
  process.stderr.write("Wrong parameters. See --help for details\n"/*,`${error}\n`*/);
  process.exit(-1);
}

const Stats = {};
let totalHighways=0;
const inFile = reader(inPath)
for(let feature of inFile.features) {
  for(let key of Object.keys(feature.properties)){
    if(key=='id') continue;
    if(key=='highway') totalHighways++;
    const tag = `${key}:${feature.properties[key]}`;
    if(typeof(Stats[tag])=='undefined') Stats[tag]=0;
    Stats[tag]++;
  }
}
Stats['total_highways'] = totalHighways;
const statsFeature = {
  "type": "Feature",
  "properties": Stats,
  "geometry": {
    "type": "Point",
      "coordinates": [
          -75.7,
          45.4
      ]
    }
};

inFile.features.push(statsFeature);

console.log(JSON.stringify(inFile, null, 2));
