// Generated by CoffeeScript 1.7.1
(function() {
  var Crawler, c, checkForQueue, counter, error, error2, first, fs, l, last, multi, output, queued, r, records, sub, visited, _i, _j, _k, _len, _len1, _len2, _ref;

  Crawler = require("crawler").Crawler;

  fs = require('fs');

  checkForQueue = function(url) {
    if (visited[url] === void 0) {
      c.queue(encodeURI(url));
      queued++;
    }
  };

  c = new Crawler({
    "maxConnections": 5,
    "skipDuplicates": true,
    "onDrain": function() {
      fs.appendFile("output.json", "]\n");
      return console.log("Finished: " + new Date());
    },
    "callback": function(error, result, $) {
      var isMain, record, _ref;
      queued--;
      record = {};
      try {
        if (error !== null) {
          console.log("" + (new Date()) + ": " + error.message);
          return;
        }
        record.uri = "http://www.yivoencyclopedia.org" + result.req.path;
        try {
          record.id = /id=([0-9]+)/g.exec($("#ctl00_placeHolderMain_linkEmailArticle").attr("href"))[1];
        } catch (_error) {
          error = _error;
          console.log("Error (" + record.uri + "): " + error.message);
          fs.appendFile("error.txt", "" + (new Date()) + " Error (" + record.uri + "): " + error.message + "\n");
          return;
        }
        visited[record.uri] = "http://www.yivoencyclopedia.org/article.aspx?id=" + record.id;
        visited["http://www.yivoencyclopedia.org/article.aspx?id=" + record.id] = record.uri;
        record.title = $("h1").text();
        record.abstract = $(".articleblockconteiner p").first().text();
        record.images = [];
        $("img.mbimg").each(function(index, img) {
          var image;
          image = {};
          image.thumbUrl = "http://www.yivoencyclopedia.org" + ($(img).attr("src"));
          image.viewerUrl = /(http.*)&article/g.exec($(img).parent().attr("href"))[1];
          image.imgDesc = $(img).parent().next().text().replace("SEE MEDIA RELATED TO THIS ARTICLE", "").trim();
          return record.images.push(image);
        });
        record.links = [];
        $("#ctl00_placeHolderMain_panelArticleText a[href^='article.aspx/']").each(function(index, a) {
          var link;
          link = {};
          link.href = "http://www.yivoencyclopedia.org/" + ($(a).attr("href"));
          link.text = $(a).text().trim();
          if (link.text.length > 0) {
            record.links.push(link);
          }
          return checkForQueue(link.href);
        });
        record.glossary = [];
        $(".term").each(function(index, span) {
          var term;
          term = $(span).text().trim();
          if (term.length > 0) {
            return record.glossary.push(term);
          }
        });
        record.subrecords = [];
        isMain = true;
        $("#ctl00_placeHolderMain_panelPager a").each(function(index, a) {
          var sr;
          sr = {};
          sr.href = "http://www.yivoencyclopedia.org" + $(a).attr("href");
          sr.page = $(a).text().trim();
          if (index === 0 && sr.href !== record.uri) {
            isMain = false;
          }
          if (!isMain && index === 0) {
            record.parent = sr.href;
            checkForQueue(sr.href);
          }
          if (isMain && index !== 0) {
            record.subrecords.push(sr);
            return checkForQueue(sr.href);
          }
        });
        record.subconcepts = [];
        $("h2.entry").each(function(index, h2) {
          var check, sc, stops;
          sc = $(h2).text().trim();
          if (index === 0 && !isMain) {
            record.title = "" + sc + " (" + record.title + ")";
            return true;
          }
          stops = ["About this Article", "Suggested Reading", "YIVO Archival Resources", "Author", "Translation"];
          check = stops.some(function(word) {
            return sc === word;
          });
          if (check) {
            return false;
          }
          return record.subconcepts.push(sc);
        });
        record.next = (_ref = $("#ctl00_placeHolderMain_linkNextArticle")) != null ? _ref.attr("href") : void 0;
        if (record.next !== void 0) {
          record.next = "http://www.yivoencyclopedia.org/" + record.next;
          checkForQueue(record.next);
        }
        records.push(record);
        fs.appendFile("output.json", (counter++ > 0 ? ",\n" : "") + JSON.stringify(record, null, 1));
        return console.log("" + counter + ". Processed " + record.uri + " (id=" + record.id + ")");
      } catch (_error) {
        error = _error;
        return fs.appendFile("error.txt", "" + (new Date()) + " Error (" + record.uri + "): " + error.message + "\n");
      }
    }
  });

  visited = {};

  counter = 0;

  queued = 0;

  records = [];

  try {
    output = fs.readFileSync("output.json");
    records = JSON.parse(output);
  } catch (_error) {
    error = _error;
    if (error.code !== "ENOENT") {
      try {
        records = JSON.parse(output + "]");
      } catch (_error) {
        error2 = _error;
        console.log(error2.message);
        return;
      }
    }
  }

  counter = records.length;

  for (_i = 0, _len = records.length; _i < _len; _i++) {
    r = records[_i];
    visited[r.uri] = "http://www.yivoencyclopedia.org/article.aspx?id=" + r.id;
    visited["http://www.yivoencyclopedia.org/article.aspx?id=" + r.id] = r.uri;
  }

  for (_j = 0, _len1 = records.length; _j < _len1; _j++) {
    r = records[_j];
    _ref = r.links;
    for (_k = 0, _len2 = _ref.length; _k < _len2; _k++) {
      l = _ref[_k];
      checkForQueue(l.href);
    }
    if (r.next !== void 0) {
      checkForQueue(r.next);
    }
  }

  console.log("Queued URLs: " + queued);

  console.log("Records loaded: " + records.length);

  first = "http://www.yivoencyclopedia.org/article.aspx/Abeles_Shimon";

  last = "http://www.yivoencyclopedia.org/article.aspx/Zylbercweig_Zalmen";

  multi = "http://www.yivoencyclopedia.org/article.aspx/Poland";

  error = "http://www.yivoencyclopedia.org/article.aspx?id=497";

  sub = "http://www.yivoencyclopedia.org/article.aspx/Poland/Poland_before_1795";

  if (counter === 0) {
    fs.writeFile("output.json", "[\n");
    c.queue(first);
  }

  console.log(new Date());

}).call(this);
