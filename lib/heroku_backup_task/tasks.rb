require "heroku_backup_task"

task :heroku_backup do
  HerokuBackupTask.execute
end

desc "Send dump file to S3"
task :heroku_backup_and_store_s3 do
  begin
    HerokuBackupTask.execute_and_store_s3
    HerokuBackupTask.remove_old_backups
  rescue => e
    puts "Error: #{e}"
    require "airbrake"
    unless Airbrake.configuration.api_key
      Airbrake.configure do |config|
        config.api_key = ENV["AIRBRAKE_KEY"]
        config.host = ENV["AIRBRAKE_HOST"]
        config.port = 443
        config.secure = config.port == 443
      end
    end
    Airbrake.notify(e)
  end
end
