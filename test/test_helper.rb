ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'mocha'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

require 'ruby-debug'

def load_schema
  config = YAML::load( File.read( File.join( File.dirname( __FILE__), "database.yml")))
  ActiveRecord::Base.logger = Logger.new( File.join( File.dirname( __FILE__), "debug.log"))
  ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :dbfile => "test/test.sqlite3")

  load File.join( File.dirname( __FILE__), "schema.rb")
  require File.join( File.dirname( __FILE__), "..", "init.rb")
end

class Project < ActiveRecord::Base
  has_many :tasks
  belongs_to :user

  accepts_nested_attributes_for :tasks, :user, :allow_destroy => true
end

class Task < ActiveRecord::Base
  belongs_to :project
  has_many :users

  accepts_nested_attributes_for :users, :allow_destroy => true
end

class User < ActiveRecord::Base
  belongs_to :task
end
