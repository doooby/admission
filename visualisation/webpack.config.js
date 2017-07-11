var path = require('path');
var UglifyJSPlugin = require('uglifyjs-webpack-plugin');

var production_build = process.env.BUILD === 'dist';

var plugins = [];
if (production_build) {
    plugins.push(new UglifyJSPlugin({output: {ascii_only: true}}));
}

module.exports = {
    entry: './index.jsx',
    output: {
        filename: 'app.js',
        path: path.resolve(__dirname, (production_build ? 'dist' : 'build'))
    },

    module: {
        rules: [
            {
                test: /\.scss$/,
                use: ['style-loader', 'css-loader', 'sass-loader']
            },
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader']
            },

            {
                test: /\.jsx?$/,
                loader: 'babel-loader',
                exclude: /node_modules/
            }
        ]
    },

    resolve: {
        extensions: ['.js', '.jsx']
    },

    plugins: plugins
};
