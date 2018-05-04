/**
 * starling
 *
 * @link https://developer.starlingbank.com/docs
 */

/* Node modules */

/* Third-party modules */
const { _ } = require('lodash');
const dayjs = require('dayjs');
const request = require('request-promise-native');

/* Files */

module.exports = class Starling {
  constructor (config, refreshToken) {
    this.config = {
      baseUrl: config.baseUrl,
      clientId: config.clientId,
      clientSecret: config.clientSecret,
      refreshToken,
      userAgent: config.userAgent
    };
  }

  /**
   * Call
   *
   * This is a common API call method
   *
   * @param {*} params
   * @param {string} token
   * @returns {*}
   * @private
   */
  _call (params, token = null) {
    const opts = _.defaultsDeep(params, {
      baseUrl: this.config.baseUrl,
      headers: {
        'user-agent': this.config.userAgent
      },
      json: true,
      method: 'GET'
    });

    if (token) {
      opts.headers.authorization = `Bearer ${token}`;
    }

    return request(opts)
      .then(result => {
        if (result._embedded) {
          return result._embedded;
        }

        return result;
      });
  }

  /**
   * Exchange Refresh Token
   *
   * Exchanges the refresh token (which never expires) for
   * an access token (which does)
   *
   * @param {string} token
   * @returns {Promise<string>}
   * @private
   */
  _exchangeRefreshToken (token = '') {
    return Promise.resolve()
      .then(() => {
        if (token) {
          return {
            'access_token': token
          };
        }

        const opts = {
          form: {
            client_id: this.config.clientId,
            client_secret: this.config.clientSecret,
            grant_type: 'refresh_token',
            refresh_token: this.config.refreshToken
          },
          method: 'POST',
          url: '/oauth/access-token'
        };

        return this._call(opts);
      })
      .then(result => result['access_token']);
  }

  getTransactions ({ from = null, to = null } = {}, token = '') {
    return this._exchangeRefreshToken(token)
      .then(refreshToken => {
        const opts = {
          qs: {},
          url: '/api/v1/transactions'
        };

        if (from) { opts.qs.from = dayjs(from).format('YYYY-MM-DD'); }
        if (to) { opts.qs.to = dayjs(to).format('YYYY-MM-DD'); }

        return this._call(opts, refreshToken);
      });
  }
};
