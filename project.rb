$LOAD_PATH.unshift 'lib'
require 'bundler/setup'
require 'dotenv'
require 'github/project'
require 'pry'

project = Github::Project.new(
  token: ENV.fetch('GH_TOKEN'),
  organization: ENV.fetch('GH_ORGANIZATION'),
  repo: ENV.fetch('GH_REPOSITORY'),
  number: ENV.fetch('GH_PROJECT')
)

project.snapshot_board
# project.generate_report

puts 'Done.'
