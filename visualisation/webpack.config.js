var path = require('path');

module.exports = {
    entry: './index.jsx',
    output: {
        filename: 'admission_visualisation.js',
        path: path.resolve(__dirname, 'build')
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
    }
};
