require 'test/unit'
require 'rubygems'
require 'active_record'
require 'active_support'
require 'active_record/fixtures'
require 'active_support/breakpoint'


require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment.rb")


ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../lib')
require File.dirname(__FILE__) + '/fixtures/test_user'
require File.dirname(__FILE__) + '/fixtures/test_comment'



config = YAML::load(IO.read(File.dirname(__FILE__) + '/../../../../config/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.establish_connection(config['test'])

load(File.dirname(__FILE__) + '/schema.rb')
Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"

