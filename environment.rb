# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

$LOAD_PATH.unshift 'lib'
require 'logger'
$logger ||= Logger.new $stdout # rubocop:disable Style/GlobalVars

require 'bundler/setup'
Bundler.require 'default', ENV['RACK_ENV']

require 'dotenv'
require 'github/project'

require 'active_record'
require_relative './models/issue'
require_relative './models/issues_sprint'
require_relative './models/sprint'
require_relative './models/project'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
