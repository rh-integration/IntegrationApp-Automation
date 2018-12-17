var config = {
development: {


    database: {
        host:   'localhost',
        user:   '',
        password: '',
        database: 'sampledb'
    },
    //3scale details
    threescale: {
         url: 'https://3scale-prod-1.app.rhdp.ocp.cloud.lab.eng.bos.redhat.com:443/cicd/maingateway/',
         token: 'ab6283abd6fd695fd4b31e8bf82d5e462c13e998'
    }
},
production: {


    //mongodb connection settings
    database: {
        host:   'mysql',
        user:   'dbuser',
        password: 'password',
        database: 'sampledb'
    },

    //3scale details
    threescale: {
        url: 'https://3scale-prod-1.app.rhdp.ocp.cloud.lab.eng.bos.redhat.com:443/cicd/maingateway/',
        token: 'ab6283abd6fd695fd4b31e8bf82d5e462c13e998'
    }

}
};
module.exports = config;
