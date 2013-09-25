###
Module dependencies.
###
express = require "express"
http = require "http"
path = require "path"

routes = {
        index: require('./routes').index
    }

app = express()

# all environments
app.set "port", process.env.PORT or 3000
app.set "views", __dirname + "/views"
app.engine ".html", require("ejs").renderFile
app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, "public"))
app.use express.static(path.join(__dirname, "views"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")

app.get "/", routes.index
app.get "/angularpartial/:partial", routes.index

http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")
