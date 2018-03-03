const reader = require('geojson-writer').reader
const bigXml = require('big-xml');

const fs = require('fs');

const args = require('minimist')(process.argv.slice(2));
let inOsmPath;
let inLTS=-1;

if (args.help) {
  const usage = `
  Usage: node prepare-osm.js [osm_file] [lts-level]

  where [osm_file] - path to osm extract, [lts-level] - lts level to generate data for (1-4)
  `;
  process.stdout.write(`${usage}\n`);
  process.exit(0);
}


try {
  inOsmPath = args._[0]
  inLTS = parseInt(args._[1])
  fs.accessSync(inOsmPath, fs.F_OK)
  if(isNaN(inLTS) || inLTS<1 || inLTS>4) throw 'bad LTS'

} catch (error) {
  process.stderr.write("Wrong parameters. See --help for details\n"/*,`${error}\n`*/);
  process.exit(-1);
}

inLTS--;

const badWays = [] //badWays contains all ways that are not suitable for the chosen LTS, i.e. for lts-1 - all that are in lts2-4
const levels = [{name: "LTS-1", inLtsJsonFile: "data/level_1.json", outLtsOsmile: "data/lts1/data.osm"},
                {name: "LTS-2", inLtsJsonFile: "data/level_2.json", outLtsOsmile: "data/lts2/data.osm"},
                {name: "LTS-3", inLtsJsonFile: "data/level_3.json", outLtsOsmile: "data/lts3/data.osm"},
                {name: "LTS-4", inLtsJsonFile: "data/level_4.json", outLtsOsmile: "data/lts4/data.osm"}]

let totalTagged = 0

for (let i=levels.length-1; i>inLTS; i--) {
  let level = levels[i]
    let ltsFile = reader(level.inLtsJsonFile)
    for(let feature of ltsFile.features) {
      if(feature.properties.id){
        const id = parseInt(feature.properties.id.split('/')[1])
        if(!isNaN(id) && id >= 0){
          badWays.push(id)
        }
      }
  }
}


console.log("<?xml version='1.0' encoding='UTF-8'?>")
console.log('<osm version="0.6" generator="osmfilter 1.4.3">')

var xml = bigXml.createReader(inOsmPath, /^(node|way|bounds|relation)$/, { gzip: false });

xml.on('record', function(record) {
  var node = '<'+record.tag
  let id=0
  for (var prop in record.attrs) {
      node += ' '+prop + '="'+record.attrs[prop].replace(/</g,'&#60;').replace(/>/g,'&#62;').replace(/'/g,'&#39;').replace(/&/g,'&#38;').replace(/\"/g, '')+'"'
      if(prop=='id'){
        id = parseInt(record.attrs[prop])
      }
  }

  if(record.tag=='way' && !isNaN(id) && badWays.includes(id))
    return;

  if(record.children && record.children.length){

    node+='>\n'
    for (var child of record.children) {
        node += '\t<'+child.tag
        for (var prop in child.attrs) {
            node += ' '+prop + '="'+child.attrs[prop].replace(/</g,'&#60;').replace(/>/g,'&#62;').replace(/'/g,'&#39;').replace(/&/g,'&#38;').replace(/\"/g, '')+'"'
        }
        node+='/>\n'
    }
    node+='</'+record.tag+'>'
  }
  else{
    node+='/>'

  }
  console.log(node);

});

xml.on('end', function() {
  console.log('</osm>')
});
