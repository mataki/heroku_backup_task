require "heroku"
require "fog"
require "open-uri"
require "pgbackups/client"
require 'active_support/core_ext'

module HerokuBackupTask; class << self

  def log(message)
    puts "[#{Time.now}] #{message}"
  end

  def backups_url
    ENV["PGBACKUPS_URL"]
  end

  def client
    @client ||= PGBackups::Client.new(ENV["PGBACKUPS_URL"])
  end

  def databases
    if db = ENV["HEROKU_BACKUP_DATABASES"]
      db.split(",").map(&:strip)
    else
      ["DATABASE_URL"]
    end
  end

  def backup_name(to_url)
    # translate s3://bucket/email/foo/bar.dump => foo/bar
    parts = to_url.split('/')
    parts.slice(4..-1).join('/').gsub(/\.dump$/, '')
  end

  def execute
    log "starting heroku backup task"

    databases.each do |db|
      db_url = ENV[db]
      log "backing up: #{db}"
      client.create_transfer(db_url, db, nil, "BACKUP", :expire => true)
    end
  end

  def execute_and_store_s3
    execute

    log "starting sending backups"

    while !transfering.empty? or !unbackuped.empty?
      unbackuped.each do |transfer|
        download(transfer)

        filename = backup_filename(transfer["to_url"])
        send_s3(transfer)
      end

      sleep 10
    end
  end

  def backup_filename(to_url)
    parts = to_url.split('/')
    parts.last
  end

  def transfering
    transfers.select{ |transfer| transfer["finished_at"].nil? }
  end

  def unbackuped
    transfers.select{ |transfer| !transfer["public_url"].nil? }.select{ |transfer| !backuped.include?(backup_filename(transfer["to_url"])) }
  end

  def transfers(cache = true)
    client.get_transfers
  end

  def backuped
    s3_dir.files.map{ |file| file.key }
  end

  def download(transfer)
    filename = backup_filename(transfer["to_url"])
    log "download #{filename}"

    File.open(filepath(filename), "wb") do |file|
      OpenURI.open_uri(transfer["public_url"]) do |dl|
        file.write(dl.read)
      end
    end
  end

  def send_s3(transfer)
    filename = backup_filename(transfer["to_url"])
    log "send #{filename} to S3"

    file = s3_dir.files.create(:key => backup_filename(transfer["to_url"]),
                               :body => File.open(filepath(filename)),
                               :public => false)
    file.save
    log "end sending"
  end

  def remove_old_backups
    s3_dir.files.each do |file|
      if file.last_modified < 1.month.ago
        log "destroy #{file.key}"
        file.destroy
      end
    end
  end

  def filepath(filename)
    if defined?(Rails)
      File.join(Rails.root, "tmp", filename)
    else
      File.join("tmp", filename)
    end
  end

  def s3_connection
    @s3_connection ||= Fog::Storage.new(:provider => 'AWS',
                                        :aws_secret_access_key => ENV["AWS_S3_SECRET_KEY"],
                                        :aws_access_key_id => ENV["AWS_S3_KEY_ID"])
  end

  def s3_dir
    s3_connection.directories.get(ENV["BACKUP_BACKET"])
  end

end; end
