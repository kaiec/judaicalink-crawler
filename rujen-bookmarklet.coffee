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

location.href = getLatinString(decodeURIComponent(location.href).replace(/(www\.)?rujen.ru\/index.php\//, "data.judaicalink.org/data/rujen/"))

# npm install -g minify
# compile -c rujen-bookmarklet.coffee
# minify rujen-bookmarklet.js
# prepend javascript:
#
#
###
javascript:(function(){var e,a,n;n=["a","b","v","g","d","e","zh","z","i","y","k","l","m","n","o","p","r","s","t","u","f","kh","ts","ch","sh","shch","j","y","j","e","yu","ya","e","e"],e=1072,a=function(a){var o,r,t,h,c,i;for(h="",t=a.toLowerCase().split(""),r=c=0,i=t.length;i>=0?i>c:c>i;r=i>=0?++c:--c)o=t[r].charCodeAt(0)-e,h+=o>=0&&34>o?n[o]:t[r];return h},location.href=a(decodeURIComponent(location.href).replace(/(www\.)?rujen.ru\/index.php\//,"data.judaicalink.org/data/rujen/"))}).call(this);
###