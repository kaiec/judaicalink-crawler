N3 = require('n3')
N3Util = N3.Util
fs = require('fs')
path = require('path');

records = []
try
	output = fs.readFileSync("rujen.json")
	records = JSON.parse(output)
catch error
	console.log error.message
	return
console.log "Records loaded: #{records.length}"

INT = "http://www.w3.org/2001/XMLSchema#integer"
a = "rdf:type"

# Helper funtions in the spirit of Grafeo
addTriple = (subject, predicate, object) ->
	subject = expand(subject)
	predicate = expand(predicate)
	object = if N3Util.isUri(object) then expand(object) else object
	# console.log("#{subject} #{predicate} #{object} .")
	writer.addTriple(subject, predicate, object)

expand = (qname) ->
	uri = qname
	try
		uri = N3Util.expandQName(uri, prefixes)
	return uri

literal = (literal, langOrType=null) ->
	res = '"' + literal + '"'
	if langOrType==null then return res
	if langOrType.length==2
		return res += "@#{langOrType}"
	else
		return res += "^^<#{langOrType}>"




prefixes = {
	"rdfs": "http://www.w3.org/2000/01/rdf-schema#",
	"owl": "http://www.w3.org/2002/07/owl#",
	"rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	"skos": "http://www.w3.org/2004/02/skos/core#",
	"dcterms": "http://purl.org/dc/terms/",
	"dc": "http://purl.org/dc/elements/1.1/"
	"dbp": "http://dbpedia.org/property/"
	"dbo": "http://dbpedia.org/ontology/"
	"dbpedia": "http://dbpedia.org/resource/"
	"foaf":    "http://xmlns.com/foaf/0.1/"
	"xsd":     "http://www.w3.org/2001/XMLSchema#"
	"jl": "http://data.judaicalink.org/ontology/"
}

local = (uri) ->
	return getLatinString(decodeURI(uri.replace("http://rujen.ru/index.php/", "http://data.judaicalink.org/data/rujen/")))

provURI = (uri) ->
	return uri.replace("http://data.judaicalink.org/data/", "http://data.judaicalink.org/data/rdf/")

gitdir = ->
	path.join(require("parentpath").sync(".git"),".git")

gitref = ->
	fs.readFileSync(path.join(gitdir(),"HEAD"), "utf8").replace("ref: ", "").trim()

githash = -> fs.readFileSync(path.join(gitdir(),gitref()), "utf8").trim()

latinUTF8Substitution = ["a", "b", "v", "g", "d", "e", "zh", "z", "i",
"y", "k", "l", "m", "n", "o", "p", "r", "s", "t", "u", "f", "kh", "ts",
"ch", "sh", "shch", "j", "y", "j", "e", "yu", "ya", "e", "e"]
UTF8TableBeginning = 1072;

getLatinString = (cyrillicString) ->
	result = "";
	input = cyrillicString.toLowerCase().split('')
	for i in [0...input.length]
		charCodeDec = input[i].charCodeAt(0)-UTF8TableBeginning
		if (charCodeDec>=0 && charCodeDec<34)
			result += latinUTF8Substitution[charCodeDec]
		else
			result += input[i]
	return result

rdfWriterRevision = githash()

writer = N3.Writer(prefixes)
for record in records
	uri = local(record.uri)
	addTriple(uri, a, "skos:Concept")
	addTriple(uri, "jl:describedAt", record.uri)
	addTriple(uri, "skos:prefLabel", literal(record.title))
	identifier = decodeURI(record.uri.replace("http://rujen.ru/index.php/", ""))
	addTriple(uri, "dcterms:identifier", literal(identifier))
	for l in record.links ? []
		addTriple(uri, "skos:related", local(l.href))
		if l.text.length>0 then addTriple(local(l.href), "skos:altLabel", literal(l.text))
	for cat in record.categories ? []
		if cat=="Персоналии"
			addTriple(uri, "jl:hasCategory", "http://data.judaicalink.org/data/rujen/person")
		else if cat=="География"
			addTriple(uri, "jl:hasCategory", "http://data.judaicalink.org/data/rujen/geography")
		else
			console.log("Unknown category: " + cat)
	if record.abstract
		addTriple(uri, "jl:hasAbstract", literal(record.abstract, "ru"))
		referTo = /^([\S]+), см\. ([\S]+)\.$/.exec(record.abstract)
		if (referTo)
			source = referTo[1]
			target = referTo[2]
			targetCheck = false
			for link in record.links ? []
				if link.href.indexOf("/#{encodeURI(target.toLowerCase())}")>0
					targetCheck = link.href
			sourceCheck = identifier==source.toLowerCase()
			if !sourceCheck || !targetCheck
				console.log("#{source} -> #{target} (#{identifier}<>#{source.toLowerCase()}) (#{targetCheck})") 
			else
				addTriple(uri, "jl:referTo", local(targetCheck))

	else if record.empty
		addTriple(uri, "skos:scopeNote", literal("The article describing this concept does not (yet) exist in the encyclopedia.", "en"))
	addTriple(provURI(uri), a, "foaf:Document")
	addTriple(provURI(uri), "foaf:primaryTopic", uri)
	addTriple(provURI(uri), "rdfs:label", literal("Metadata"))
	addTriple(provURI(uri), "dcterms:created", literal(record.created, expand("xsd:dateTime")))
	addTriple(provURI(uri), "jl:crawlerRevision", literal(record.githash))
	addTriple(provURI(uri), "jl:rdfWriterRevision", literal(rdfWriterRevision))


addTriple("http://data.judaicalink.org/data/rujen/person", a, "skos:Concept")
addTriple("http://data.judaicalink.org/data/rujen/person", "jl:describedAt", "http://www.rujen.ru/index.php/%D0%9A%D0%B0%D1%82%D0%B5%D0%B3%D0%BE%D1%80%D0%B8%D1%8F:%D0%9F%D0%B5%D1%80%D1%81%D0%BE%D0%BD%D0%B0%D0%BB%D0%B8%D0%B8")
addTriple("http://data.judaicalink.org/data/rujen/person", "skos:prefLabel", literal("Person", "en"))

addTriple("http://data.judaicalink.org/data/rujen/geography", a, "skos:Concept")
addTriple("http://data.judaicalink.org/data/rujen/geography", "jl:describedAt", "http://www.rujen.ru/index.php/%D0%9A%D0%B0%D1%82%D0%B5%D0%B3%D0%BE%D1%80%D0%B8%D1%8F:%D0%93%D0%B5%D0%BE%D0%B3%D1%80%D0%B0%D1%84%D0%B8%D1%8F")
addTriple("http://data.judaicalink.org/data/rujen/geography", "skos:prefLabel", literal("Geography", "en"))

writer.end (error, result) -> fs.writeFile("rujen.n3", result)
