cli = require('commander')
fs = require('fs')
csv = require('csv')

cli
  .version('0.0.1')
  .usage('[options] <JSON file ...>')
  .option('-p, --persons', 'Extract persons')
  .option('-c, --csv <fields>', 'Write CSV', (v) -> v.split(','))
  .option('-o, --output <file>', 'Write output to file')
  .option('-f, --filter <filter>', 'Filter output')
  .parse(process.argv)

csvDelimiter = '\t'
 
records = []
try
	output = fs.readFileSync(cli.args[0])
	records = JSON.parse(output)
catch error
	console.error error.message
	return
console.error "Records loaded: #{records.length}"

wstream = if cli.output 
		fs.createWriteStream(cli.output) 
	else
		process.stdout 


if (cli.csv)
	wstream.write("sep=\t\n# ")
	csvStream = csv.stringify({delimiter: csvDelimiter})
	csvStream.on 'readable', ->
		while(row = csvStream.read())
   			wstream.write(row)
	csvStream.on 'error', ->
		console.error(err.message)
	csvStream.on 'finish', ->

	data = []
	for field in cli.csv
		data.push field
	csvStream.write(data)
	for record in records
		if cli.filter
			continue unless eval(cli.filter)
		data = []
		for field in cli.csv
			data.push(record[field])
		csvStream.write(data)