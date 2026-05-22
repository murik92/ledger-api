class ReconciliationJob
  include Sidekiq::Job

  def perform
    puts "Starting reconciliation job..."

    ReconciliationService.call

    puts "Reconciliation job completed"
  rescue StandardError => e
    puts "Reconciliation failed: #{e.message}"

    raise e
  end
end
