$:.unshift File.expand_path("../lib", __FILE__)

require "rubygems"
require "heroku_backup_task/version"

Gem::Specification.new do |gem|
  gem.name     = "heroku_backup_task"
  gem.version  = HerokuBackupTask::VERSION

  gem.authors   = "David Dollar, Joe Sak"
  gem.email    = "joe@joesak.com"
  gem.homepage = "http://github.com/joemsak/heroku_backup_task"

  gem.summary  = "Automate your Heroku backups. Many thanks & kudos to David for writing this gem."

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|spec/|test/)} }

  gem.add_dependency "heroku", ">= 1.13.7"
  gem.add_dependency "rake"
  gem.add_dependency "fog"
end
