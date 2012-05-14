/*
          CouchPress Installer Script 
  Please do not modify anything below this line 
 -----------------------------------------------
*/

var read   = require('read')
  , fs     = require('fs')
  , cradle = require('cradle')
  , path   = require('path')
  , crypto = require('crypto')
  , packageJSON = require('../package.json')
  , data = {}
  , admin = {}
  ;

try {
  var old = require('../config.js')
  data = old.config;
  admin = old.admin;
} catch (excp) {
  data = {
    site : {
      title       :"CouchPress Site",
      description :"Just another CouchPress Site",
      copyright   :"Joe Bloggs",
      twitter     :"joebloggs",
      port        :"3000",
      secret      :"somethingsecret",
      version     : packageJSON.version
    },
    theme: {
      admin: "admin",
      front:"soothe"
    },
    db:{
      host:"http://localhost",
      port:"5984"
    }
  }
  admin = {
    user :"admin",
    pass :"admin"
  }
}
var site = data.site
  , theme = data.theme
  , db = data.db;

function init (cb){
  console.log('\n\t Welcome to the CouchPress installation process ')
  console.log('I\'m going to ask you some question, respond only the true ;)\n')
  promiseChain(cb)
  (function(cb){
    var mo = Object.keys(packageJSON.dependencies);
    if (path.existsSync(__dirname + '/../node_modules')){
      var modules = fs.readdirSync(__dirname +'/../node_modules')
      var validKeys = mo.filter(function(v){
        return modules.indexOf(v) > -1;
      });
      if (mo.length === validKeys.length) return cb()
      return cb(new Error('You need to run `npm install` before this script'))
    }
  })
  ( read
    , [{prompt: "Site Title: ", default: site.title}]
    , function (n) { site.title = n }
  )
  ( read
    , [{prompt:"Site Description: ",default: site.description}]
    , function (n) {site.description = n}
  ) 
  ( read
    , [{prompt:"Copyright: ",default: site.copyright}]
    , function (n) {site.copyright = n}
  )
  ( read
    , [{prompt:"Twitter Handler: ",default: site.twitter}]
    , function (n) {site.twitter = n}
  )
  ( read
    , [{prompt:"Port to listen: ",default: site.port}]
    , function (n) {site.port = n}
  )
  ( read
    , [{prompt:"Secret word: ",default: site.secret}]
    , function (n) {site.secret = n}
  )
  (function(cb){
    console.log('\n\t:: Now we are going to setup the theme ::\n');
    return cb()
  })
  ( read
    , [{prompt:"Admin theme: ",default: theme.admin}]
    , function (n) {theme.admin = n}
  )
  ( read
    , [{prompt:"Front theme: ",default: theme.front}]
    , function (n) {theme.front = n}
  )
  (function(cb){
    console.log('\n\t:: Database Setup ::\n');
    return cb()
  })
  ( read
    , [{prompt:"Database host: ",default: db.host}]
    , function (n) {db.host = n}
  )
  ( read
    , [{prompt:"Database port: ",default: db.port}]
    , function (n) {db.port = n}
  )
  (read
    , [{prompt:"Database username: ",default: admin.user}]
    , function (n) {admin.user = n}
  )
  (read
    , [{prompt:"Username pass: ",default: admin.pass}]
    , function (n) {admin.pass = n}
  )
  (function(cb){
    console.log('\n\t:: About to write ::\n');
    console.log('config = ', data ,'\nadmin = ', admin);
    read({ prompt: "\nIs this ok? ", default: "yes" }, function (er, ok) {
      if (er) return cb(er)
      if (ok.toLowerCase().charAt(0) !== "y") {
        return cb(new Error("cancelled"))
      } 
      return cb();
    })
  })
  (function(cb){
    var template = 'exports.config = '+ JSON.stringify(data, null, 2) +
                  ';\nexports.admin = '+ JSON.stringify(admin, null, 2);
    fs.writeFile('./config.js',template,'utf8', function(err,resp){
      if (err) return cb(err)
      console.log('config.js wrote sucessfully')
      return cb();
    });
  })
  (function(cb){
    read({ prompt: "\nInstall default views to database? ", default: "yes" }, function (er, ok) {
      if (er) return cb(er)
      if (ok.toLowerCase().charAt(0) !== "y") {
        return cb(new Error("cancelled"))
      } 
      installViews(data,cb);
    });
  })
  (function(cb){
    read({ prompt: "\nDo you want to add an extra user? ", default: "yes" }, function (er, ok) {
      if (er) return cb(er)
      if (ok.toLowerCase().charAt(0) !== "y") {
        return cb()
      } else {
        var user ={}
        promiseChain(cb)
        ( read
          , [{prompt:"Username:",default:"dave"}]
          , function (n) {user.user = n}
        )
        (read
          , [{prompt:"Password:",default:"dave"}]
          , function (n) { user.password = n}
        )
        ( read
          , [{prompt:"email:",default:"dave@example.com"}]
          , function (n) { user.email = n}
        )(function(cb){
           var url =  data.db.host;
          if (!~url.indexOf('://')) url = 'http://' + url;
          var c = new(cradle.Connection)(url,data.db.port,{
             auth: { username: admin.user, password: admin.pass }
          });
          var salt = crypto.createHash('md5').update(new Date().toString()).update(Math.random().toString()).digest('hex');
          var toSave = {
            _id      : 'org.couchdb.user:'+ user.user,
            name     : user.user,
            salt     : salt,
            password : crypto.createHash('sha1').update(user.password.trim()+salt).digest('hex'),
            email    : user.email,
            roles    : [],
            type     : 'user'
          };
          var db = c.database('_users');
          db.save(toSave, function(err,resp){
            if (err && err.error !== 'conflict') return cb(err);
            else if (err) console.log('\nI can\'t update your username already exists'); return cb();
            console.log('User saved...');
            return cb();
          });
        })(function(cb){
          return cb();
        })()
      }
    })
  })
  (function (cb) {
    console.log('\nNow run `node server`\n\n:: Done :: ');
   })();
}

function installViews(data,cb){

  
  var url =  data.db.host
  if (!~url.indexOf('://')) url = 'http://' + url;
  var c = new(cradle.Connection)(url,data.db.host,{
     auth: { username: admin.user, password: admin.pass }
  });
  var db = c.database('couchpress');
  function seed(){
    db.save('_design/couchpress', {
      views: {
        all: {
          map: 'function(doc) {\n  if (doc.type !== \'upload\')\n    emit(doc.created_at, doc);\n}\n'
        },
        tag: {
          map: function(doc) {
            for (tag in doc.tags) {
              emit(doc.tags[tag], doc)
            }
          }
        },
        uploads_all: {
          map: function(doc) {
            if (doc.type === 'upload') {
              emit(doc.created_at, doc);
            }
          }
        }
      }
    }, function(error,res){
      if (error) return cb(error);
      console.log('\n Database and views saved...');
      return cb();
    });
  }
  db.exists(function (err, exists) {
    if (err) {
      return cb(new Error(err));
    } else if (exists) {
      seed();
    } else {
      db.create();
      setTimeout(seed , 500);
    }
  });
}

function promiseChain (cb) {
  var steps = []
    , vals = []
    , context = this
  function go () {
    var step = steps.shift()
    if (!step) return cb()
    try { step[0].apply(context, step[1]) }
    catch (ex) { cb(ex) }
  }
  return function pc (fn, args, success) {
    if (arguments.length === 0) return go()
    // add the step
    steps.push
      ( [ fn
        , (args || []).concat([ function (er) {
            if (er) return cb(er)
            var a = Array.prototype.slice.call(arguments, 1)
            try { success && success.apply(context, a) }
            catch (ex) { return cb(ex) }
            go()
          }])
        ]
      )
    return pc
  }
}
console.log("\n\
       _____             _                       \n\
      |     |___ _ _ ___| |_ ___ ___ ___ ___ ___ \n\
      |   --| . | | |  _|   | . |  _| -_|_ -|_ -|\n\
      |_____|___|___|___|_|_|  _|_| |___|___|___|\n\
                            |_|                  \n\
")
init(function(err){
  console.log(err)
})