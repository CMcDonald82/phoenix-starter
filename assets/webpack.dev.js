const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const path = require("path");
const webpack = require('webpack');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = merge(common, {
  devtool: 'inline-source-map',
  devServer: {
    headers: {
      "Access-Control-Allow-Origin": "*"
    },
    hot: true
  },
  output: {
    publicPath: 'http://0.0.0.0:8080/'
  },
  module: {
    rules: [
      // CSS/SASS
      {
        test: /\.(css|scss)$/,
        exclude: /node_modules/,
        include: /css/,
        use: [
          'style-loader',
          'css-loader',
          'sass-loader'
        ]
      }
    ]
  },
  plugins: [
    new CopyWebpackPlugin([{
      from: './static',
      to: path.resolve(__dirname, '../priv/static')
    }]),
    new webpack.HotModuleReplacementPlugin(),
  ]
});