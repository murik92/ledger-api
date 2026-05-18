if defined?(Sidekiq) && Sidekiq.server?
  schedule_file =
    Rails.root.join("config/schedule.yml")

  if File.exist?(schedule_file)
    schedule =
      YAML.load_file(schedule_file)

    Sidekiq::Cron::Job.load_from_hash(schedule)

    puts "Loaded cron schedule"
  end
end