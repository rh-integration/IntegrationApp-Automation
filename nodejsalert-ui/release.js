#!/usr/bin/env node

'use strict';

/*
 *
 *  Copyright 2016-2017 Red Hat, Inc, and individual contributors.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

// This file is run during the "postbump" lifecyle of standard-version
// We need to be able to update the metadata.label.verion of the resource objects in the openshift template in the .openshiftio folder

const {promisify} = require('util');
const fs = require('fs');
const jsyaml = require('js-yaml');
const packagejson = require('./package.json');

const writeFile = promisify(fs.writeFile);
const readFile = promisify(fs.readFile);

async function updateApplicationYaml () {
  const applicationyaml = jsyaml.safeLoad(await readFile(`${__dirname}/.openshiftio/application.yaml`, {encoding: 'utf8'}));
  // We just need to update the RELEASE_VERSION parameter
  applicationyaml.parameters = applicationyaml.parameters.map(param => {
    if (param.name === 'RELEASE_VERSION') {
      param.value = packagejson.version;
    }

    return param;
  });

  // Now write the file back out
  await writeFile(`${__dirname}/.openshiftio/application.yaml`, jsyaml.safeDump(applicationyaml, {skipInvalid: true}), {encoding: 'utf8'});
}

updateApplicationYaml();
