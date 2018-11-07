var fs = require('fs');
var Crawler = require("./crawler");


var processPage = function (error,result,$) {
    // $ is a jQuery instance scoped to the server-side DOM of the page
    // console.log "Processing #{result.url}"
    var record = {};
    try {
	record.uri = result.url;
        record.title = $("#content h2:first-of-type").text();
	record.articles = [];
	$("h4.atl").parent().each(function() {
	    var article = {};
	    article.title = $(this).children("h4.atl").first().text();
	    article.author =  $(this).children("p.aug").first().text();
	    article.citation = $(this).children("p.journal").first().text();
	    record.articles.push(article);
	});
        next = "http://www.palgrave-journals.com" + $(".next").attr("href");
	console.log("Next: " + next);
        crawler.checkForQueue(next);
	return record;
    } catch(error) {
	fs.appendFile("error.txt", new Date() + " Error (" + record.uri + "): " + error.message + "\n");
	return null;
    }
}

var crawler = new Crawler(processPage, "macmillan-jibs.json");
crawler.restart("http://www.palgrave-journals.com/jibs/journal/v1/n1/index.html");
