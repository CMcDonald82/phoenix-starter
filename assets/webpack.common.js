const path = require('path');
const webpack = require('webpack');

module.exports = {
  // recommended to pass a value in for context per Webpack docs: https://webpack.js.org/configuration/entry-context/
  context: __dirname, 
  resolve: {
    modules: ["node_modules", __dirname],
    extensions: [".js", ".json", ".jsx", ".css", ".scss"]
  },
  entry: {
    app: ['./js/app.js', './css/app.scss'] 
  },
  output: {
    path: path.resolve(__dirname, '../priv/static'),
    filename: 'js/[name].js'
  },
  module: {
    rules: [
      // JS/JSX
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        include: /js/,
        use: ['babel-loader']
      },
      // Images
      {
        test: /\.(png|svg|jpg|gif)$/,
        exclude: /node_modules/,
        use: [
          'file-loader'
        ]
      },
      // Fonts
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/,
        exclude: /node_modules/,
        use: [
          'file-loader'
        ]
      }
    ]
  }

};