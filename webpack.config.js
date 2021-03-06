const fs = require('fs');
const node_modules = fs.readdirSync('node_modules').filter(x => x !== '.bin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
// const WebpackShellPlugin = require('webpack-shell-plugin');


//const globby = require('globby');


//fs.writeFileSync('test/all.ts',
//  globby.sync(['test/**/*-test.ts', 'test/**/*-test.tsx'])
//    .map(file => file.replace('test/', '').replace(/\.tsx?$/, ''))
//   .map(file => `import './${file}';`)
//   .join('\n'));

module.exports = [{
  target: 'web',
  entry: './src/ui/client',
  output: {
    path: __dirname + '/dist/js-frontend',
    filename: 'client.js'
  },
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: 'ts-loader'
      },
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract('css-loader?sourceMap!less-loader?sourceMap')
      },
      {
        test: /\.less$/,
        loader: ExtractTextPlugin.extract('css-loader?sourceMap!less-loader?sourceMap')
      },
      {
        test: /\.(jpe?g|png|gif|svg)$/i,
        loaders: [ 'url-loader?limit=10000', 'img-loader?minimize' ],
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "url-loader?limit=10000&mimetype=application/font-woff"
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "file-loader"
      }
    ]
  },
  devtool: 'source-map',
  resolve: {
    extensions: ['.tsx', '.ts', '.webpack.js', '.web.js', '.js']
  },
  plugins: [
    new ExtractTextPlugin('styles.css'),
    new HtmlWebpackPlugin({
      template: './src/ui/index.ejs'
    })
  ]
},{
  target: 'node',
  entry: './src/server/server',
  output: {
    path: __dirname + '/dist',
    filename: 'server.js',
    libraryTarget: 'commonjs2'
  },
  module: {
    loaders: [
      {
        test: /\.tsx?$/,
        loader: 'awesome-typescript-loader?useBabel=false'
      }
    ]
  },
  externals: node_modules,
  devtool: 'source-map',
  resolve: {
    extensions: ['.ts', '.webpack.js', '.web.js', '.js']
  }
},
{
  target: 'node',
  entry: './src/endpoints/car-list/handler',
  output: {
    path: __dirname + '/dist/car-list.serverless',
    filename: 'handler.js',
    libraryTarget: 'commonjs2'
  },
  module: {
    loaders: [
      {
        test: /\.tsx?$/,
        loader: 'awesome-typescript-loader?useBabel=false'
      }
    ]
  },
  externals: node_modules,
  devtool: 'source-map',
  resolve: {
    extensions: ['.ts', '.webpack.js', '.web.js', '.js']
  }
}
,
{
  target: 'node',
  entry: './src/endpoints/service-list/handler',
  output: {
    path: __dirname + '/dist/service-list.serverless',
    filename: 'handler.js',
    libraryTarget: 'commonjs2'
  },
  module: {
    loaders: [
      {
        test: /\.tsx?$/,
        loader: 'awesome-typescript-loader?useBabel=false'
      }
    ]
  },
  externals: node_modules,
  devtool: 'source-map',
  resolve: {
    extensions: ['.ts', '.webpack.js', '.web.js', '.js']
  }
}
,
{
  target: 'node',
  entry: './src/endpoints/user-info/handler',
  output: {
    path: __dirname + '/dist/user-info.serverless',
    filename: 'handler.js',
    libraryTarget: 'commonjs2'
  },
  module: {
    loaders: [
      {
        test: /\.tsx?$/,
        loader: 'awesome-typescript-loader?useBabel=false'
      }
    ]
  },
  externals: node_modules,
  devtool: 'source-map',
  resolve: {
    extensions: ['.ts', '.webpack.js', '.web.js', '.js']
  }
}
  
  ,{
  target: 'node',
  entry: './test/all',
  output: {
    path: __dirname + '/dist',
    filename: 'test.js',
    libraryTarget: 'commonjs2'
  },
  module: {
    loaders: [
      {
        test: /\.tsx?$/,
        loader: 'awesome-typescript-loader?useBabel=false'
      },
      {
        test: /\.css$/,
        loader: 'style-loader!css-loader!less-loader'
      },
      {
        test: /\.less$/,
        loader: 'style-loader!css-loader!less-loader'
      },
      {
          test: /\.png$/,
          loader: "url-loader",
          query: { mimetype: "image/png" }
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "url-loader?limit=10000&mimetype=application/font-woff"
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "file-loader"
      }
    ]
  },
  externals: node_modules,
  devtool: 'source-map',
  resolve: {
    extensions: ['.tsx', '.ts', '.webpack.js', '.web.js', '.js']
  }
}];
