/**
 * handler
 */

/* Node modules */
const fs = require('fs');

/* Third-party modules */
const yml = require('js-yaml');

/* Files */
const Starling = require('./starling');

function secretOrEnvvar (secretFile, envvar) {
  let value;
  try {
    value = fs.readFileSync(secretFile, 'utf8');
  } catch (err) {
    value = process.env[envvar];
  }

  return value;
}

const config = {
  baseUrl: process.env.BASE_URL,
  exchangeTokens: process.env.EXCHANGE_TOKENS !== 'false',
  clientId: secretOrEnvvar('/run/secrets/starling_client_id', 'CLIENT_ID'),
  clientSecret: secretOrEnvvar('/run/secrets/starling_client_secret', 'CLIENT_SECRET'),
  userAgent: 'OpenFAAS-starling'
};

module.exports = input => Promise
  .resolve()
  .then(() => {
    /* JSON is valid YAML */
    const inputArgs = yml.safeLoad(input);

    const { args = [], method, refreshToken } = inputArgs;

    const obj = new Starling(config, refreshToken);

    return obj[method](...args);
  });
