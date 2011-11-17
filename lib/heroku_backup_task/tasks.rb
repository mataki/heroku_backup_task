require "heroku_backup_task"

task :heroku_backup do
  HerokuBackupTask.execute
end

task :heroku_backup_and_store_s3 do
  HerokuBackupTask.execute_and_store_s3
  HerokuBackupTask.remove_old_backups
end
