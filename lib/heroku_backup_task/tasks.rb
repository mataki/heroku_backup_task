require "heroku_backup_task"

task :heroku_backup do
  HerokuBackupTask.execute
end

def send_error(error)
  if key = ENV["AIRBRAKE_KEY"] and host = ENV["AIRBRAKE_HOST"]
    puts "send error to airbrake: #{key}: #{host}"
    require "airbrake"
    unless Airbrake.configuration.api_key
      Airbrake.configure do |config|
        config.api_key = key
        config.host = host
        config.environment_name = ENV["AIRBRAKE_ENV"] || "production"
        config.port = 443
        config.secure = config.port == 443
      end
    end
    Airbrake.notify(error)
  else
    puts "skip send error to airbrake"
  end
rescue => e
  Rails.logger.error "[Error] #{e}" if defined?(Rails)
  puts e
rescue LoadError => e
  msg = "[Load Error] airbrake is not bundled. #{e}"
  Rails.logger.error msg if defined?(Rails)
  puts msg
end

desc "Send dump file to S3"
task :heroku_backup_and_store_s3 do
  begin
    HerokuBackupTask.execute_and_store_s3
    HerokuBackupTask.remove_old_backups
  rescue => e
    puts "Error: #{e}"
    send_error(e)
  end
end
