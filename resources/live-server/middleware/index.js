/**
 * Middleware so I can use non-web files from live-server
 */

const handler = require("./markdown-handler");

module.exports = function(req, res, next) {

    console.log(req.method + " " + req.url);
    handler(req.url, res, next);
}
