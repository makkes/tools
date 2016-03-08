/* global Promise */
/* eslint-env mocha */

'use strict';

var cache = require('./cache.js');
var should = require('should');

describe('cache', function() {

    afterEach(function() {
        cache.clear();
    });

    describe('get', function() {
        it('should return a promise', function() {
            var p = cache.get('key', function() {
                return Promise.resolve(42);
            });
            (p instanceof Promise).should.be.ok;
        });
        it('should resolve to correct value', function(done) {
            var p = cache.get('key', function() {
                return Promise.resolve(99);
            });
            p.then(function(value) {
                value.should.equal(99);
                done();
            }).then(undefined, function(e) {
                done(e);
            });
        });
    });
    it('should call the "missing" callback on 1st invocation', function(done) {
        cache.get('key', function() {
            done();
            return Promise.resolve(42);
        });
    });
    it('should not call the "missing" callback on 2nd synchronous invocation', function(done) {
        cache.get('key', function() {
            return Promise.resolve('value');
        }).then(function() {});
        cache.get('key', function() {
            throw Error('"missing" callback called 2 times');
        }).then(function(value) {
            value.should.equal('value');
            done();
        });
    });
    it('should not call the "missing" callback on 2nd asynchronous invocation', function(done) {
        cache.get('key', function() {
            return new Promise(function(resolve) {
                setTimeout(function() {
                    resolve('value');
                }, 0);
            });
        });
        cache.get('key', function() {
            throw Error('"missing" callback called 2 times');
        }).then(function(value) {
            value.should.equal('value');
            done();
        });
    });
    it('should always return the same value for a key', function(done) {
        var cnt = 0;
        cache.get('key', function() {
            return Promise.resolve(42);
        }).then(function(val) {
            val.should.equal(42);
            cnt++;
        });
        cache.get('key', function() {
            return Promise.resolve(43);
        }).then(function(val) {
            val.should.equal(42);
            cnt.should.equal(1);
            done();
        });
    });

    describe('remove', function() {
        it('should return a promise', function() {
            var p = cache.remove('key');
            (p instanceof Promise).should.be.ok;
        });
        it('should resolve', function(done) {
            cache.remove(55).then(function() {
                done();
            });
        });
        it('should reject without argument', function(done) {
            cache.remove().then(undefined, function() {
                done();
            });
        });
        it('should remove stored keys', function(done) {
            cache.storeSync('k1', 'v1');
            cache.remove('k1').then(function() {
                should(cache.getSync('k1')).not.exist;
                done();
            }).then(undefined, function(e) {
                done(e);
            });
        });
        it('should remove all keys with prefix', function(done) {
            cache.storeSync('prefix:1', 'val1');
            cache.storeSync('prefix:2', 'val2');
            cache.remove(/^prefix:/).then(function() {
                should.not.exist(cache.getSync('prefix:1'));
                should.not.exist(cache.getSync('prefix:2'));
                done();
            });
        });
    });

    describe('clear', function() {
        it('should clear all values from cache', function(done) {
            // fill cache with k1=42
            cache.get('k1', function() {
                return Promise.resolve(42);
            }).then(function(v1) {
                // now fill cache with k2=43 and return both values
                return Promise.all([v1, cache.get('k2', function() {
                    return Promise.resolve(43);
                })]);
            }).then(function(values) {
                var callbacksInvoked = 0;
                values[0].should.equal(42);
                values[1].should.equal(43);
                // clear the cache
                cache.clear();
                // both callbacks must be invoked
                cache.get('k1', function() {
                    if (++callbacksInvoked == 2) {
                        done();
                    }
                    return Promise.resolve('new 42');
                });
                cache.get('k2', function() {
                    if (++callbacksInvoked == 2) {
                        done();
                    }
                    return Promise.resolve('new 43');
                });
            }).catch(function(err) {
                done(err);
            });
        });
    });

    describe('synchronous functionality', function() {
        it('should return undefined for missing value', function() {
            should.not.exist(cache.getSync('doesntexist'));
        });
        it('should return stored value', function() {
            cache.storeSync('key', 'value');
            cache.getSync('key').should.equal('value');
        });
    });
});
