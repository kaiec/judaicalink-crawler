Crawler = require("crawler").Crawler
fs = require('fs');

# Helper function that only queues a URL if we haven't visited it yet.
checkForQueue = (url) ->
	if visited[url]==undefined
		# console.log("Queued: " + url + " Encoded: " + encodeURI(url))
		c.queue(encodeURI(url))
		queued++
		return 

c = new Crawler {
	"maxConnections": 5,
	"skipDuplicates": true,
	# When finished, close the array in the output file
	"onDrain": ->
		fs.appendFile("output.json", "]\n")
		console.log("Finished: " + new Date())
	#This will be called for each crawled page
	"callback": (error,result,$) ->
		# $ is a jQuery instance scoped to the server-side DOM of the page
		queued--
		record = {}
		try

			if (error!=null)
				console.log("#{new Date()}: #{error.message}")
				return

			# Identifiers (in this case URI and numerical ID)
			record.uri = "http://www.yivoencyclopedia.org#{result.req.path}"
			try
				record.id = /id=([0-9]+)/g.exec($("#ctl00_placeHolderMain_linkEmailArticle").attr("href"))[1]
			catch error
				console.log("Error (#{record.uri}): #{error.message}")
				fs.appendFile("error.txt", "#{new Date()} Error (#{record.uri}): #{error.message}\n")
				return
			# Mark as visited
			visited[record.uri]="http://www.yivoencyclopedia.org/article.aspx?id=#{record.id}"
			visited["http://www.yivoencyclopedia.org/article.aspx?id=#{record.id}"] = record.uri

			# Basic stuff
			record.title = $("h1").text()
			record.abstract = $(".articleblockconteiner p").first().text()

			# Images
			record.images = []
			$("img.mbimg").each (index, img) ->
				image = {}
				image.thumbUrl = "http://www.yivoencyclopedia.org#{$(img).attr("src")}"
				image.viewerUrl = /(http.*)&article/g.exec($(img).parent().attr("href"))[1]
				image.imgDesc = $(img).parent().next().text().replace("SEE MEDIA RELATED TO THIS ARTICLE","").trim()
				record.images.push image

			# Links
			record.links = []
			$("#ctl00_placeHolderMain_panelArticleText a[href^='article.aspx/']").each (index,a) ->
				link = {}
				link.href = "http://www.yivoencyclopedia.org/#{$(a).attr("href")}"
				link.text = $(a).text().trim()
				record.links.push link if link.text.length>0 # Strangely, there are sometimes empty links
				checkForQueue link.href

			# Glossary terms
			record.glossary = []
			$(".term").each (index,span) ->
				term = $(span).text().trim()
				record.glossary.push term if term.length>0  # Strangely, there are sometimes empty spans

			# Subrecords, i.e., multi-page articles (like Poland)
			record.subrecords = []
			isMain =true
			$("#ctl00_placeHolderMain_panelPager a").each (index,a) ->
				sr = {}
				sr.href = "http://www.yivoencyclopedia.org" + $(a).attr("href")
				sr.page = $(a).text().trim()
				if index==0 and sr.href!=record.uri then isMain = false
				if !isMain and index==0
					record.parent = sr.href
					checkForQueue sr.href
				if isMain and index!=0
					record.subrecords.push sr
					checkForQueue sr.href

			# Subconcepts, i.e., H2 headings on the same page (not really a concept, but maybe useful)
			record.subconcepts = []
			$("h2.entry").each (index,h2) ->
				sc = $(h2).text().trim()
				if index==0 and !isMain 
					record.title = "#{sc} (#{record.title})"
					return true
				# The following H2 headings are NOT stored as concepts:
				stops = ["About this Article", "Suggested Reading", "YIVO Archival Resources", "Author", "Translation"]
				check = stops.some (word) -> sc==word
				if check
					return false
				record.subconcepts.push sc

			# Next record in alphabet			
			record.next = $("#ctl00_placeHolderMain_linkNextArticle")?.attr("href")
			if record.next!=undefined 
				record.next = "http://www.yivoencyclopedia.org/#{record.next}"
				# console.log("Next: #{record.next}")
				checkForQueue record.next

			# Store the result
			records.push record
			fs.appendFile("output.json", (if counter++>0 then ",\n" else "") + JSON.stringify(record,null,1))
			console.log("#{counter}. Processed #{record.uri} (id=#{record.id})")
		catch error
			fs.appendFile("error.txt", "#{new Date()} Error (#{record.uri}): #{error.message}\n")
	}


visited = {} # Map of visited URLs (Needed as we have two URLs per page, ?id= and /title)
counter = 0
queued = 0
records = []

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
	visited[r.uri]="http://www.yivoencyclopedia.org/article.aspx?id=#{r.id}"
	visited["http://www.yivoencyclopedia.org/article.aspx?id=#{r.id}"] = r.uri

# Queue all link from pages that we already visited
for r in records
	for l in r.links
		checkForQueue l.href
	if r.next!=undefined then checkForQueue r.next

console.log("Queued URLs: " + queued)
console.log("Records loaded: #{records.length}")

# Example URIs for testing
first = "http://www.yivoencyclopedia.org/article.aspx/Abeles_Shimon"
last = "http://www.yivoencyclopedia.org/article.aspx/Zylbercweig_Zalmen"
multi = "http://www.yivoencyclopedia.org/article.aspx/Poland"
error = "http://www.yivoencyclopedia.org/article.aspx?id=497"
sub = "http://www.yivoencyclopedia.org/article.aspx/Poland/Poland_before_1795"

# If there are no previous records, create a new output file and 
# start with first page
if counter==0
	fs.writeFile("output.json", "[\n")
	c.queue(first);

# Log start time
console.log(new Date())

