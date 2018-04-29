#!/usr/bin/env bash

# install base packages
npm i -g \
    @types/node \
    babel-cli \
    babel-register \
    babel-preset-env \
    babel-preset-flow \
    flow-bin \
    http-server \
    npx \
    ts-node \
    typescript \
    tslint \
    tslint-config-airbnb \
    tslint-eslint-rules \
    @angular/cli



# install eslint as suggested by airbnb https://github.com/airbnb/javascript/tree/master/packages/eslint-config-airbnb-base
(
  export PKG=eslint-config-airbnb-base;
  npm info "$PKG@latest" peerDependencies --json | command sed 's/[\{\},]//g ; s/: /@/g' | xargs npm i -g "$PKG@latest"
)

# install babel for eslint and flow plugin
npm i -g \
    babel-eslint \
    eslint-plugin-flowtype
