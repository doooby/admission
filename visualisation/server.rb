#!/usr/bin/env ruby

require 'rubygems'
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require_relative '../lib/admission'
require_relative '../lib/admission/visualisation_app'
require_relative '../spec/test_context/index'

require 'rack'
require 'byebug'

Rack::Handler::WEBrick.run Admission::VisualisationApp.new(
    js_entry: Pathname.new(__FILE__).join('..', 'build', 'admission_visualisation.js'),
    order: -> () {
      {
          privileges: PRIVILEGES_ORDER,
          rules: RESOURCE_RULES
      }
    }
)