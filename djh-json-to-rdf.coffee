N3 = require('n3')
N3Util = N3.Util
fs = require('fs')

records = []
try
	output = fs.readFileSync("djh.json")
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
	return uri.replace("http://dasjuedischehamburg.de/inhalt/", "http://data.judaicalink.org/data/djh/")

writer = N3.Writer(prefixes)
for record in records
	uri = local(record.uri)
	addTriple(uri, a, "skos:Concept")
	if (record.isPerson) 
		addTriple(uri, a, "foaf:Person")
		addTriple(uri, "jl:occupation", literal(record.occupation, "de")) if record.occupation
		addTriple(uri, "jl:birthDate", literal(record.birthDate, "de")) if record.birthDate
		addTriple(uri, "jl:birthLocation", literal(record.birthLocation, "de")) if record.birthLocation
		addTriple(uri, "jl:deathDate", literal(record.deathDate, "de")) if record.deathDate
		addTriple(uri, "jl:deathLocation", literal(record.deathLocation, "de")) if record.deathLocation
	addTriple(uri, "jl:describedAt", record.uri)
	addTriple(uri, "skos:prefLabel", literal(record.title))
	for l in record.links 	
		addTriple(uri, "skos:related", local(l.href))
		if l.text.length>0 then addTriple(local(l.href), "skos:altLabel", literal(l.text))
	addTriple(uri, "jl:hasAbstract", literal(record.abstract, "de"))
writer.end (error, result) -> fs.writeFile("djh.n3", result)
