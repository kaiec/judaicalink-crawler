// Generated by CoffeeScript 1.7.1
(function() {
  var INT, N3, N3Util, a, addTriple, error, expand, fs, l, literal, local, output, prefixes, record, records, sc, scu, sr, uri, writer, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;

  N3 = require('n3');

  N3Util = N3.Util;

  fs = require('fs');

  records = [];

  try {
    output = fs.readFileSync("output.json");
    records = JSON.parse(output);
  } catch (_error) {
    error = _error;
    console.log(error.message);
    return;
  }

  console.log("Records loaded: " + records.length);

  INT = "http://www.w3.org/2001/XMLSchema#integer";

  a = "rdf:type";

  addTriple = function(subject, predicate, object) {
    subject = expand(subject);
    predicate = expand(predicate);
    object = N3Util.isUri(object) ? expand(object) : object;
    return writer.addTriple(subject, predicate, object);
  };

  expand = function(qname) {
    var uri;
    uri = qname;
    try {
      uri = N3Util.expandQName(uri, prefixes);
    } catch (_error) {}
    return uri;
  };

  literal = function(literal, langOrType) {
    var res;
    if (langOrType == null) {
      langOrType = null;
    }
    res = '"' + literal + '"';
    if (langOrType === null) {
      return res;
    }
    if (langOrType.length === 2) {
      return res += "@" + langOrType;
    } else {
      return res += "^^<" + langOrType + ">";
    }
  };

  prefixes = {
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "owl": "http://www.w3.org/2002/07/owl#",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "skos": "http://www.w3.org/2004/02/skos/core#",
    "dcterms": "http://purl.org/dc/terms/",
    "dc": "http://purl.org/dc/elements/1.1/",
    "dbp": "http://dbpedia.org/property/",
    "dbo": "http://dbpedia.org/ontology/",
    "dbpedia": "http://dbpedia.org/resource/",
    "foaf": "http://xmlns.com/foaf/0.1/",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "jl": "http://data.judaicalink.org/ontology/"
  };

  local = function(uri) {
    return uri.replace("http://www.yivoencyclopedia.org/article.aspx/", "http://data.judaicalink.org/data/yivo/");
  };

  writer = N3.Writer(prefixes);

  for (_i = 0, _len = records.length; _i < _len; _i++) {
    record = records[_i];
    uri = local(record.uri);
    addTriple(uri, a, "skos:Concept");
    addTriple(uri, "jl:describedAt", record.uri);
    addTriple(uri, "skos:prefLabel", literal(record.title));
    _ref = record.links;
    for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
      l = _ref[_j];
      addTriple(uri, "skos:related", local(l.href));
      if (l.text.length > 0) {
        addTriple(local(l.href), "skos:altLabel", literal(l.text));
      }
    }
    addTriple(uri, "jl:hasAbstract", literal(record.abstract, "en"));
    _ref1 = record.subconcepts;
    for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
      sc = _ref1[_k];
      scu = uri + "/" + encodeURI(sc.replace(/[ ]+/g, "_"));
      addTriple(scu, a, "skos:Concept");
      addTriple(scu, "skos:broader", uri);
      addTriple(scu, "skos:prefLabel", literal(sc));
      addTriple(uri, "skos:narrower", scu);
    }
    _ref2 = record.subrecords;
    for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
      sr = _ref2[_l];
      addTriple(uri, "skos:narrower", local(sr.href));
    }
    if (record.broader !== void 0) {
      addTriple(uri, "skos:broader", local(record.broader));
    }
  }

  writer.end(function(error, result) {
    return fs.writeFile("output.n3", result);
  });

}).call(this);
