var express = require('express');
var request = require('request');
var router = express.Router();

// home page
router.get('/', function(req, res, next) {

    var db = req.con;
    var data = "";
    var url = req.config.threescale.url;
    var token=req.config.threescale.token;
    var user = "";
    var user = req.query.user;

    var filter = "";
    if (user) {
        filter = 'WHERE id = ?';
    }

    db.query('SELECT * FROM userprofile ' + filter, user, function(err, rows) {
        if (err) {

            console.log(err);
        }
        var data = rows;

        // use index.ejs
        res.render('index', { title: 'CICD Demo', data: data, user: user, url:url , token:token });
    });

});

// add page
router.get('/add', function(req, res, next) {

    // use userAdd.ejs
    res.render('userAdd', { title: 'Add User', msg: '' });
});

// add post
router.post('/userAdd', function(req, res, next) {

    var db = req.con;

    // check userid exist
    var userid = req.body.id;
    var qur = db.query('SELECT id FROM userprofile WHERE id = ?', userid, function(err, rows) {
        if (err) {
            console.log(err);
        }

        var count = rows.length;
        if (count > 0) {

            var msg = 'Userid already exists.';
            res.render('userAdd', { title: 'Add User', msg: msg });

        } else {

            var sql = {
                id: req.body.id,
                firstName: req.body.firstName,
                lastName: req.body.lastName,
                phone: req.body.phone,
                addr: req.body.addr,
                state: req.body.state,
                email: req.body.email,
                username: 'rusername'
            };

            console.log(sql);
            var qur = db.query('INSERT INTO userprofile SET ?', sql, function(err, rows) {
                if (err) {
                    console.log(err);
                }
                res.setHeader('Content-Type', 'application/json');
                res.redirect('/');
            });
        }
    });


});

// edit page
router.get('/userEdit', function(req, res, next) {

    var id = req.query.id;
    //console.log(id);

    var db = req.con;
    var data = "";

    db.query('SELECT * FROM userprofile WHERE id = ?', id, function(err, rows) {
        if (err) {
            console.log(err);
        }

        var data = rows;
        res.render('userEdit', { title: 'Edit userprofile', data: data });
    });

});


router.post('/userEdit', function(req, res, next) {

    var db = req.con;

    var id = req.body.id;

    var sql = {
      id: req.body.id,
      firstName: req.body.firstName,
      lastName: req.body.lastName,
      phone: req.body.phone,
      addr: req.body.addr,
      state: req.body.state,
      email: req.body.email,
      username: 'rusername'
    };

    var qur = db.query('UPDATE userprofile SET ? WHERE id = ?', [sql, id], function(err, rows) {
        if (err) {
            console.log(err);
        }

        res.setHeader('Content-Type', 'application/json');
        res.redirect('/');
    });

});


router.get('/userAlert', function(req, res, next) {

    var id = req.query.id;
    var alertType = req.query.alertType;
    var db = req.con;


     var url='http://maingateway-service-cicddemo.app.rhdp.ocp.cloud.lab.eng.bos.redhat.com/cicd/maingateway/profile/'+id+'?alertType='+alertType

    request(url, function (error, response, body) {
      if (!error && response.statusCode == 200) {

        console.log(body) // Show the HTML for the Google homepage.
          res.redirect('/');
      }


    });


  //  request({
  //      uri: 'http://maingateway-service-cicddemo.app.rhdp.ocp.cloud.lab.eng.bos.redhat.com/cicd/maingateway/profile/'+id+'?alertType='+alertType,
  //      qs: {
  //        api_key: '123456',
  //        query: 'World of Warcraft: Legion'
  //      }
  //    }).pipe(res);
    //  res.redirect('/');

});

module.exports = router;
