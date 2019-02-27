var config = {
development: {

    //mysql connection settings for development
    database: {
        host:   'localhost',
        user:   'root',
        password: '',
        database: 'sampledb'
    },
    //3scale details
    threescale: {
         url: 'http://3scalefuse-staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com',
         token: 'c8515bb07dd5694f5b457306b402b53a'
    }
},
production: {


    //mysql connection settings for production
    database: {
        host:   'mysql',
        user:   'dbuser',
        password: 'password',
        database: 'sampledb'
    },

    //3scale details
    threescale: {
        url: 'http://3scalefuse-staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com',
        token: 'c8515bb07dd5694f5b457306b402b53a'
    }

}
};
module.exports = config;
