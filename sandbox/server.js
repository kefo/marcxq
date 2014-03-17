// imports
var express = require('express');
var fs = require('fs');
var server = express();
var path = require('path');
var zorba = require('zorba');

/*

    What would be needed to go from here?
    
    Let's say we need two components:
        1) Mongodb to get the data out in a structure *I* define and it predictable
            a) This layer should allow us to get rid of 4store.
        2) Elasticsearch to handle search needs.


    load data

*/

// configure application
server.configure(function () {
  //server.set('views', __dirname + '/views');
  //server.set('view engine', 'jade');
  server.use(express.bodyParser());
});

server.configure('development', function () {
  server.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
  server.use(express.static(__dirname + '/public_html'));
});

server.configure('production', function () {
  server.use(express.errorHandler());
  server.use(express.static(__dirname + '/public_html', {maxAge: 60*15*1000}));
});

server.use(function (req, res){
  
  fs.readFile("../xbin/zorba.xqy", {encoding: 'utf8'}, function(err, data) {
        //declare variable $marcxmluri as xs:string external;
        
        //query = data.replace(/at "..\//g, 'at "/home/kefo/Desktop/marklogic/id/id-main/marcxq/');
        query = data.replace(/at "..\//g, 'at "/home/kefo/Desktop/Kevin/Active/marklogic/id/id-main/marcxq/');
        query = query.replace('$s as xs:string external;', '$s := "' + req.query.s + '";');
        query = query.replace('$i as xs:string external;', '$i := "' + req.query.i + '";');
        query = query.replace('$o as xs:string external;', '$o := "' + req.query.o + '";');
  
        /*
        zorba.execute(query, function(err, data) {
            if (req.query.o == "json") {
                data = data.replace('<?xml version="1.0" encoding="UTF-8"?>' + "\n", "")
                res.header("Content-Type", "text/plain");
            } else {
                res.header("Content-Type", "application/xml");
            }
            res.end(data);
        });
        */
        try {
            var r = zorba.execute(query);
            if (req.query.o == "json") {
                r = r.replace('<?xml version="1.0" encoding="UTF-8"?>' + "\n", "")
                res.header("Content-Type", "text/plain");
            } else {
                res.header("Content-Type", "application/xml");
            }
            res.end(r);
        } catch (e) {
            var err = JSON.parse(e["message"]);
            errout = "Error! \n";
            errout += "    " + err["error"] + "\n";
            //errout += "        type: " + err["type"] + "\n";
            if (err.file === "") {
                errout += "        file: zorba.xqy\n";
            } else {
                errout += "        file: " + err["file"] + "\n";
            }
            errout += "        line(s): " + err["lines"] + "\n";
            errout += "        character(s): " + err["characters"] + "\n";
            res.header("Content-Type", "text/plain");
            res.end(errout);
        }
    });
  
});

server.listen(8281);
console.log('Server started; Listening on port 8281');

