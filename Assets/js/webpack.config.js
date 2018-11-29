const path = require('path');

module.exports = {
  mode: 'production',
  entry: './src/app.js',
  output: {
    filename: 'bundle.js',
    path: path.join(__dirname, 'dist')
  }
};