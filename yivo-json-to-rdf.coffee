N3 = require('n3')
N3Util = N3.Util
fs = require('fs')
path = require('path');

records = []
try
	output = fs.readFileSync("yivo.json")
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
	return uri.replace("http://www.yivoencyclopedia.org/article.aspx/", "http://data.judaicalink.org/data/yivo/").
	replace(/%C5%82/g, "l").replace(/%C5%81/g, "L").
	replace(/%C5%BB/g, "Z").replace(/%C5%BA/g, "z").
	replace(/%E1%B8%A5/g, "h").replace(/%E1%B8%A4/g, "H").
	replace(/%E2%80%98/g, "").replace(/%E2%80%93/g,"-").
	replace(/%E2%80%99/g, "_").replace(/%C2%A0/g,"_").
	replace(/%E2%80%9C/g, "").replace(/%E2%80%9D/g,"").
	replace(/%C3%B3/g, "o")

provURI = (uri) ->
	return uri.replace("http://data.judaicalink.org/data/", "http://data.judaicalink.org/data/rdf/")

gitdir = ->
	path.join(require("parentpath").sync(".git"),".git")

gitref = ->
	fs.readFileSync(path.join(gitdir(),"HEAD"), "utf8").replace("ref: ", "").trim()

githash = -> fs.readFileSync(path.join(gitdir(),gitref()), "utf8").trim()

rdfWriterRevision = githash()

writer = N3.Writer(prefixes)
for record in records
	uri = local(record.uri)
	addTriple(uri, a, "skos:Concept")
	addTriple(uri, "jl:describedAt", record.uri)
	addTriple(uri, "skos:prefLabel", literal(record.title))
	for l in record.links 	
		addTriple(uri, "skos:related", local(l.href))
		if l.text.length>0 then addTriple(local(l.href), "skos:altLabel", literal(l.text))
	addTriple(uri, "jl:hasAbstract", literal(record.abstract, "en"))
	for sc in record.subconcepts
		scu = local uri + "/" + encodeURI(sc.replace(/[ ]+/g, "_"))
		addTriple(scu, a, "skos:Concept")
		addTriple(scu, "skos:broader", uri)
		addTriple(scu, "skos:prefLabel", literal(sc))
		addTriple(uri, "skos:narrower", scu)
	for sr in record.subrecords
		addTriple(uri, "skos:narrower", local(sr.href))
	if record.broader!=undefined
		addTriple(uri, "skos:broader", local record.broader)
	addTriple(provURI(uri), a, "foaf:Document")
	addTriple(provURI(uri), "foaf:primaryTopic", uri)
	addTriple(provURI(uri), "rdfs:label", literal("Metadata"))
	addTriple(provURI(uri), "dcterms:created", literal(record.created, expand("xsd:dateTime")))
	addTriple(provURI(uri), "jl:crawlerRevision", literal(record.githash))
	addTriple(provURI(uri), "jl:rdfWriterRevision", literal(rdfWriterRevision))
writer.end (error, result) -> fs.writeFile("yivo.n3", result)
