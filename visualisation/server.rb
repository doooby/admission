#!/usr/bin/env ruby

require 'rubygems'
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'rack'
require 'byebug'

require_relative '../lib/admission'
require_relative '../lib/admission/visualisation'
require_relative '../spec/test_context/index'

Admission::Visualisation.set :js_entry,
    Admission::Visualisation::ASSETS_PATH.join('build', 'admission_visualisation.js')

Admission::Visualisation.set :admission_data,
    {
        order: PRIVILEGES_ORDER,
        rules: ACTIONS_RULES,
        arbitrator: Admission::Arbitration
    }


Rack::Handler::WEBrick.run Admission::Visualisation