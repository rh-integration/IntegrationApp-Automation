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
         url: 'https://',
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
        url: 'https://',
        token: '8d94e11870361bbfe81dd2c692c829ca6a2c09ac'
    }

}
};
module.exports = config;
