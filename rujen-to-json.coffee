http = require('http')
cheerio = require('cheerio')
fs = require('fs');


visited = {} # Map of visited URLs (Needed as we have two URLs per page, ?id= and /title)
counter = 0
queued = 0
queue = []
records = []

maxSockets = 100
http.globalAgent.maxSockets = maxSockets

lowerCase = (url) ->
	encodeURI(decodeURI(url).toLowerCase())

# Helper function that only queues a URL if we haven't visited it yet.
checkForQueue = (url) ->
	if visited[url]==undefined and queue.indexOf(url)<0
		# console.log("Queued: " + url + " Encoded: " + encodeURI(url))
		queue.push(url)
		console.log("Queued: " + url)
		queued++
		processQueue()
		return

running = 0
request = (url, callback, redirect) ->
	# console.log "request #{url}, redirect: #{redirect}"
	if redirect==undefined
		running++
		redirect = url
	req = http.get redirect, (res) ->
		# console.log "Resonse: #{res.statusCode}"
		if res.statusCode>=300 and res.statusCode < 307
			request(url, callback, res.headers["location"])
			res.on "data", ->
			return
		if res.statusCode!=200
			e = new Error("Server Error: #{res.statusCode}, URL: #{url}, Requested: #{redirect}")
			e.url = url
			callback(e)
			res.on "data", ->
			requestComplete()
			return
		html = ""
		res.on "data", (chunk) ->
			# console.log "Chunk"
			html += chunk
		res.on "end", ->
			# console.log "No more data"
			# console.log "Preparing response: html=#{html}, res.data=#{res.data}" 
			res.data = html if (res.data==undefined)
			# console.log "Preparing response: url=#{url}, res.url=#{res.url}" 
			res.url = url
			callback(null, res, cheerio.load(html))
			requestComplete()
	req.on "error", (e) ->
		e.url = url
		callback(e)
		requestComplete()

requestComplete = ->
	running--
	if (running==0) then processQueue()

processQueue = ->
	if (queue.length==0 and running==0)
		finish()
		return

	if (running==0)
		toProcess = queue.splice(0,maxSockets)
		for q in toProcess
			request(q,processRujenPage)
		# console.log("New crawling started with queue size #{toProcess.length} (Queue: #{queue.length})")
	return 


# When finished, close the array in the output file
finish = ->
	fs.appendFile("output.json", "]\n")
	console.log("Finished: " + new Date())

processRujenPage = (error,result,$) ->
	# $ is a jQuery instance scoped to the server-side DOM of the page
	# console.log "Processing #{result.url}"
	queued--
	record = {}
	try
		if (error!=null)
			console.log "#{new Date()}: #{error.message}"
			checkForQueue error.url
			return

		# check for index pages
		if (result.url.indexOf("AllPages")!=-1)
			# Links
			console.log("Processing Index Page: " + result.url)
			$("td a").each (index,a) ->
				page = "http://rujen.ru#{$(a).attr("href")}"
				page = lowerCase(page)
				checkForQueue lowerCase page
			$("#bodyContent p a").last().each (index,a) ->
				console.log("Next index page: " + "http://rujen.ru#{$(a).attr("href")}")
				checkForQueue "http://rujen.ru#{$(a).attr("href")}"
			return

		# Identifiers (in this case URI and numerical ID)
		record.uri = lowerCase result.url
		try            # var wgArticleId = "13645";
			record.id = /var wgArticleId = "?([0-9]+)"?;/g.exec($("head").html())[1]
		catch error
			console.log("Error getting ID (#{record.uri}): #{error.message}")
			fs.appendFile("error.txt", "#{new Date()} Error getting ID (#{record.uri}): #{error.message}\n")
			return

		# Have we been there in the meantime?
		if visited[record.uri]=""
			return

		# Mark as visited
		visited[record.uri]=""
		

		# Basic stuff
		record.title = $("h1.firstHeading").text()
		
		# Not yet written
		if record.id=="0"
			record.empty="true"
			records.push record
			fs.appendFile("output.json", (if counter++>0 then ",\n" else "") + JSON.stringify(record,null,1))
			console.log("#{counter}. Processed #{record.uri} (id=#{record.id}) (R/Q/Q=#{running}/#{queued}/#{queue.length})")
			return
		if record.id=="1"
			return

		record.abstract = $("#bodyContent>p").text().replace("\\n","").trim()

		# Links
		record.links = []
		$("#bodyContent>p>a").each (index,a) ->
			link = {}
			h = "http://rujen.ru#{$(a).attr("href").replace("&action=edit&redlink=1","").replace("?title=","/")}"
			link.href = lowerCase(h)
			link.text = $(a).text().trim()
			record.links.push link if link.text.length>0 # Strangely, there are sometimes empty links
			checkForQueue link.href

		#Category
		record.categories = []
		$("#catlinks span a").each (index,a) ->
			record.categories.push($(a).text().trim())

		# Store the result
		records.push record
		fs.appendFile("output.json", (if counter++>0 then ",\n" else "") + JSON.stringify(record,null,1))
		console.log("#{counter}. Processed #{record.uri} (id=#{record.id}) (R/Q/Q=#{running}/#{queued}/#{queue.length})")
	catch error
		fs.appendFile("error.txt", "#{new Date()} Error (#{record.uri}): #{error.message}\n")



# Load previous results, if not yet finished
try
	output = fs.readFileSync("output.json")
	records = JSON.parse(output)
catch error
	if error.code!="ENOENT" 
		try
			records = JSON.parse(output + "]")
		catch error2
			console.log error2.message
			return
counter = records.length

# Recreate the map of visited URLs
for r in records
	visited[r.uri]=""

# Queue all link from pages that we already visited
for r in records
	if r.links
		for l in r.links
			checkForQueue l.href

console.log("Queued URLs: " + queued)
console.log("Records loaded: #{records.length}")

# Example URIs for testing
firstIndex = "http://rujen.ru/index.php/%D0%A1%D0%BB%D1%83%D0%B6%D0%B5%D0%B1%D0%BD%D0%B0%D1%8F:AllPages/%D0%90%D0%91%D0%90%D0%97%D0%9E%D0%92%D0%9A%D0%90"
# firstIndex = "http://rujen.ru/index.php/Служебная:AllPages/АБАЗОВКА"
# If there are no previous records, create a new output file and 
# start with first page
if counter==0
	fs.writeFile("output.json", "[\n")

# Queue Index page anyway to get all pages
checkForQueue firstIndex

# Log start time
console.log(new Date())

