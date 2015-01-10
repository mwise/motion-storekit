# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require './lib/motion-storekit'

begin
  require 'bundler'
  require 'motion/project/template/gem/gem_tasks'
  Bundler.require
rescue LoadError
end

require 'guard/motion'
require 'bacon-expect'
require 'motion_print'
require 'motion-redgreen'
require 'motion-stump'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'motion-storekit'
  app.redgreen_style = :progress
end
