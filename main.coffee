# Requires and Variables
exp = require 'express'
app = exp.createServer()

# Articler Class
Articler = require('./articler').Articler
article = new Articler 'http://localhost', 5984
 
# App Configuration
app.configure () ->
    app.set 'view engine', 'jade'
    app.set 'views', __dirname + '/views'
    app.use exp.static __dirname + '/public'
    app.use exp.bodyParser()
    app.use exp.methodOverride()
 
# Run App
app.listen 1337
console.log 'Server running at http://localhost:1337/'

# Routing
app.get '/', (req, res) ->
    article.findAll (err, docs) ->
        res.render 'index',
            locals:
                title: 'CouchPress'
                articles: docs

app.get '/new', (req, res) ->
    res.render 'new', {locals: {title: 'CouchPress / New Post'}}

app.post '/new', (req, res) ->
    article.save {
        title: req.param 'title'
        body: req.param 'body'
        created_at: new Date()
    }, (err, docs) ->
        res.redirect('/')