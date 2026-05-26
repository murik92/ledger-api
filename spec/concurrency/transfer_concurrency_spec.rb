require "rails_helper"

RSpec.describe "Transfer concurrency" do
  def create_account(balance:)
    user = User.create!(
      email: "#{SecureRandom.uuid}@test.com",
      password: "password123"
    )

    account = Account.create!(
      user: user,
      name: SecureRandom.uuid,
      currency: "USD",
      balance_cents: 0,
      opening_balance_cents: 0
    )

    if balance > 0
      AccountFundingService.call(
        account: account,
        amount_cents: balance
      )
    end

    account.reload
  end

  it "prevents double spending under concurrency" do
    from = create_account(balance: 100_00)
    to = create_account(balance: 0)

    threads = []

    successful_transfers = Queue.new
    errors = Queue.new

    10.times do
      threads << Thread.new do
        begin
          ActiveRecord::Base.connection_pool.with_connection do
            reference = SecureRandom.uuid

            TransferService.call(
              from: from.reload,
              to: to.reload,
              amount_cents: 20_00,
              reference: reference,
              idempotency_key: SecureRandom.uuid
            )

            successful_transfers << reference
          end
        rescue StandardError => e
          errors << e
        end
      end
    end

    threads.each(&:join)

    from.reload
    to.reload

    aggregate_failures do
      expect(from.balance_cents).to eq(0)

      expect(to.balance_cents).to eq(100_00)

      total_balance =
        from.balance_cents +
        to.balance_cents

      expect(total_balance).to eq(100_00)

      expect(successful_transfers.size).to eq(5)

      expect(errors.size).to be >= 5
    end
  end
end
