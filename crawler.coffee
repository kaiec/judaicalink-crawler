http = require('http')
cheerio = require('cheerio')
fs = require('fs');

if typeof String.prototype.endsWith != 'function'
	String.prototype.endsWith = (suffix) ->
		return @indexOf(suffix, @length - suffix.length) != -1;


if typeof String.prototype.truncate != 'function'
	String.prototype.truncate = (limit, append) -> 
    if (typeof append == 'undefined')
        append = '...';
    parts = @match(/\S+/g)
    if (parts!=null and parts.length > limit)
    	parts.length=limit
    	parts.push(append)
    	return parts.join(' ')
    return @

class Crawler
	
	constructor: (@processPage, @outputFile="output.json") ->
		@visited = {} # Map of visited URLs (Needed as we have two URLs per page, ?id= and /title)
		@counter = 0
		@queue = []
		@records = []
		@running = []

		@maxSockets = 10
		http.globalAgent.maxSockets = @maxSockets


	restart: (@seed) ->
		# Load previous results, if not yet finished
		try
			output = fs.readFileSync(@outputFile)
			@records = JSON.parse(output)
		catch error
			if error.code!="ENOENT" 
				try
					@records = JSON.parse(output + "]")
				catch error2
					console.log error2.message
					return

		# Recreate the map of visited URLs
		for r in @records
			@visited[r.uri]="visited"

		# Queue all link from pages that we already visited
		# and write out existing records
		fs.writeFile(@outputFile, "[\n")
		for r in @records
			fs.appendFile(@outputFile, (if @counter++>0 then ",\n" else "") + JSON.stringify(r,null,1))
			if r.links
				for l in r.links
					@checkForQueue l.href

		console.log("Queued URLs: " + @queue.length)
		console.log("Records loaded: #{@records.length}")

		
		# Queue Index page anyway to get all pages
		@checkForQueue @seed

		# Log start time
		console.log(new Date())

	# Helper function that only queues a URL if we haven't visited it yet.
	checkForQueue: (url) ->
		if @visited[url]==undefined and @queue.indexOf(url)<0 and @running.indexOf(url)<0
			# console.log("Queued: " + url + " Encoded: " + encodeURI(url))
			console.log("Queued: '#{url}' (#{@visited[url]}/#{@queue.indexOf(url)}/#{@running.indexOf(url)})")
			@queue.push(url)
			@processQueue()
			return

	request: (url, callback, redirect) ->
		console.log "Running: #{url}, redirect: #{redirect}"
		@running.push(url)
		if redirect==undefined
			redirect = url
		req = http.get redirect, (res) =>
			# console.log "Resonse: #{res.statusCode}"
			if res.statusCode>=300 and res.statusCode < 307
				@request(url, callback, res.headers["location"])
				res.on "data", ->
				return
			if res.statusCode!=200
				e = new Error("Server Error: #{res.statusCode}, URL: #{url}, Requested: #{redirect}")
				e.url = url
				callback(e)
				res.on "data", ->
				@requestComplete()
				return
			html = ""
			res.on "data", (chunk) =>
				# console.log "Chunk"
				html += chunk
			res.on "end", =>
				# console.log "No more data"
				# console.log "Preparing response: html=#{html}, res.data=#{res.data}" 
				res.data = html if (res.data==undefined)
				# console.log "Preparing response: url=#{url}, res.url=#{res.url}" 
				res.url = url
				record = callback(null, res, cheerio.load(html))
				if record!=null
					@records.push record
					fs.appendFile(@outputFile, (if @counter++>0 then ",\n" else "") + JSON.stringify(record,null,1))	
					# Mark as visited
					@visited[record.uri]="visited"
					@visited[url]="visited"
					@visited[redirect]="visited"
					console.log("#{@counter}. Processed #{record.uri} (id=#{record.id}) (R/Q=#{@running.length}/#{@queue.length})")
				@requestComplete(url)
		req.on "error", (e) =>
			e.url = url
			callback(e)
			@requestComplete(url)

	requestComplete: (url) ->
		@running.splice(@running.indexOf(url),1)
		if (@running.length==0) then @processQueue()

	processQueue: ->
		# console.log "Checking queue: #{@queue.length}, Running: #{@running}"
		if (@queue.length==0 and @running.length==0)
			@finish()
			return

		if (@running.length==0)
			toProcess = @queue.splice(0,@maxSockets)
			for q in toProcess
				@request(q,@processPage)
			# console.log("New crawling started with queue size #{toProcess.length} (Queue: #{queue.length})")
		return 


	# When finished, close the array in the output file
	finish: ->
		fs.appendFile(@outputFile, "]\n")
		console.log("Finished: " + new Date())



module.exports = Crawler