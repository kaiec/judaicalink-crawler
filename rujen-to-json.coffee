fs = require('fs');
Crawler = require("./crawler")


lowerCase = (url) ->
	encodeURI(decodeURI(url).toLowerCase())

processRujenPage = (error,result,$) ->
	# $ is a jQuery instance scoped to the server-side DOM of the page
	# console.log "Processing #{result.url}"
	record = {}
	try
		if (error!=null)
			console.log "#{new Date()}: #{error.message}"
			crawler.checkForQueue error.url
			return null

		# check for index pages
		if (result.url.indexOf("AllPages")!=-1)
			# Links
			console.log("Processing Index Page: " + result.url)
			$("td a").each (index,a) ->
				page = "http://rujen.ru#{$(a).attr("href")}"
				page = lowerCase(page)
				crawler.checkForQueue lowerCase page
			$("#bodyContent p a").last().each (index,a) ->
				console.log("Next index page: " + "http://rujen.ru#{$(a).attr("href")}")
				crawler.checkForQueue "http://rujen.ru#{$(a).attr("href")}"
			return null

		# Identifiers (in this case URI and numerical ID)
		record.uri = lowerCase result.url
		try            # var wgArticleId = "13645";
			record.id = /var wgArticleId = "?([0-9]+)"?;/g.exec($("head").html())[1]
		catch error
			console.log("Error getting ID (#{record.uri}): #{error.message}")
			fs.appendFile("error.txt", "#{new Date()} Error getting ID (#{record.uri}): #{error.message}\n")
			return null

		

		# Basic stuff
		record.title = $("h1.firstHeading").text()
		
		# Not yet written
		if record.id=="0"
			record.empty="true"
			return record
		if record.id=="1"
			return null

		record.abstract = $("#bodyContent>p").text().replace("\\n","").trim()

		# Links
		record.links = []
		$("#bodyContent>p>a").each (index,a) ->
			link = {}
			h = "http://rujen.ru#{$(a).attr("href").replace("&action=edit&redlink=1","").replace("?title=","/")}"
			link.href = lowerCase(h)
			link.text = $(a).text().trim()
			record.links.push link if link.text.length>0 # Strangely, there are sometimes empty links
			crawler.checkForQueue link.href

		#Category
		record.categories = []
		$("#catlinks span a").each (index,a) ->
			record.categories.push($(a).text().trim())

		return record
	catch error
		fs.appendFile("error.txt", "#{new Date()} Error (#{record.uri}): #{error.message}\n")
		return null



crawler = new Crawler(processRujenPage)
crawler.restart("http://rujen.ru/index.php/%D0%A1%D0%BB%D1%83%D0%B6%D0%B5%D0%B1%D0%BD%D0%B0%D1%8F:AllPages/%D0%90%D0%91%D0%90%D0%97%D0%9E%D0%92%D0%9A%D0%90")
