var http = require('http');
var fs = require('fs');
var program = require('commander');

program
  .version('0.0.1')
  .option('-p, --port <value>', 'port to listen on (default)', '8888')
  .parse(process.argv);

var httpServer = http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  var resMsg = "METHOD : " + req.method + "\nURL : "+ req.url + "\nHEADERS : " +  JSON.stringify(req.headers,null,' ');
  res.end(resMsg);
  console.log("--- REQ ---");
  console.log(resMsg);
})

httpServer.on('error',function(err) {
   console.log("error : " + err);
});

httpServer.listen(program.port);
console.info("start listening on http://localhost:"+ program.port);
