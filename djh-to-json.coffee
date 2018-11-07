Crawler = require("./crawler")
fs = require('fs');

processPage = (error,result,$) ->
	# $ is a jQuery instance scoped to the server-side DOM of the page
	record = {}
	try

		if (error!=null)
			console.log("#{new Date()}: #{error.message}")
			return null

		# Identifier 
		record.uri = "http://dasjuedischehamburg.de#{result.req.path}"

		# Basic stuff
		record.title = $("h1.title").text()

		record.abstract = ""
		p = $("div.content p").first()
		record.abstract = p.text().trim()
		if record.abstract.length>0 and not record.abstract.endsWith(".") then record.abstract += ". "
		lifedates = record.abstract # if there are lifedates, they have to be in the first p
		record.isPerson = (lifedates.match(/\d{4}.+\d{4}/)!=null)
		p = p.next("p")
		record.abstract += p.text().trim()
		p = p.next("p")
		record.abstract += p.first().text().trim()
		record.abstract = record.abstract.split("→").join("")
		record.abstract = record.abstract.truncate(100)
		# Intendant, Musiker und Komponist, geb. 14.9.1910 Zürich, gest. 2.1.1999 Paris
		lifedates = lifedates.match(/(.*)geb\. (.*), gest\. (.*?)\. /)
		if lifedates != null
			occupation = lifedates[1].trim()
			record.occupation = occupation.replace(/,\s*$/g, '')
			birth = lifedates[2].match(/(.*[0-9].)(\D*)/)
			if birth!=null
				record.birthDate = birth[1].trim()
				record.birthLocation = birth[2].trim()
			death = lifedates[3].match(/(.*[0-9].)(\D*)/)
			if death!=null
				record.deathDate = death[1].trim()
				record.deathLocation = death[2].trim()

		record.author = $("div.content div.field-field-name div.field-items div.field-item").first().text().trim()

		# Images
		record.images = []
		$("img.image").each (index, img) ->
			image = {}
			image.thumbUrl = "#{$(img).attr("src")}"
			image.imgDesc = $(img).attr("alt").trim()
			record.images.push image

		# Links
		record.links = []
		$("div.content p.text a[href*='/inhalt/']").each (index,a) ->
			link = {}
			link.href = $(a).attr("href").replace(/.*\/inhalt\//,"http://dasjuedischehamburg.de/inhalt/")
			link.text = $(a).text().trim()
			record.links.push link if link.text.length>0 # Strangely, there are sometimes empty links
			crawler.checkForQueue link.href

		# Glossary terms
		record.glossary = []
		$(".term").each (index,span) ->
			term = $(span).text().trim()
			record.glossary.push term if term.length>0  # Strangely, there are sometimes empty spans


		# Next record in alphabet			
		record.next = $("a.page-next")?.attr("href")
		if record.next!=undefined 
			record.next = "http://dasjuedischehamburg.de#{record.next}"
			# console.log("Next: #{record.next}")
			crawler.checkForQueue record.next

		# Store the result
		if record.uri.match(/^.*\/[a-z]$/) 
			# console.log("Match: " + record.uri)
			return null 
		else
			# console.log("Added: " + record.uri)
			return record
	catch error
		fs.appendFile("error.txt", "#{new Date()} Error (#{record.uri}): #{error.message} Stack: #{error.stack}\n")
		return null


crawler = new Crawler(processPage, "djh.json")
crawler.restart("http://dasjuedischehamburg.de/inhalt/a")

