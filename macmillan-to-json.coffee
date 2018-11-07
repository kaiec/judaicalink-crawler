fs = require('fs');
Crawler = require("./crawler")


lowerCase = (url) ->
	encodeURI(decodeURI(url).toLowerCase())

processPage = (error,result,$) ->
	# $ is a jQuery instance scoped to the server-side DOM of the page
	# console.log "Processing #{result.url}"
	record = {}
	try
		if (error!=null)
			console.log "#{new Date()}: #{error.message}"
			crawler.checkForQueue error.url
			return null

                # Identifiers (in this case URI and numerical ID)
		record.uri = lowerCase result.url
                record.title = $("#content h2:first-of-type").text()
                next = $(".next").attr("href")
                crawler.ceckForQueue next
		return record
	catch error
		fs.appendFile("error.txt", "#{new Date()} Error (#{record.uri}): #{error.message}\n")
		return null

crawler = new Crawler(processPage, "macmillan-jibs.json")
crawler.restart("http://www.palgrave-journals.com/jibs/journal/v1/n1/index.html")
