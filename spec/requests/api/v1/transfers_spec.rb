require 'swagger_helper'

RSpec.describe 'API V1 Transfers', type: :request do

    def create_account_with_balance(
  name:,
  currency:,
  balance_cents:
)
  system = Account.system_account

  account = Account.create!(
    name: name,
    currency: currency,
    balance_cents: balance_cents,
    opening_balance_cents: balance_cents
  )

  transaction = LedgerTransaction.create!(
    reference: "initial-balance-#{name}-#{SecureRandom.uuid}",
    status: "completed",
    idempotency_key:
      "initial-key-#{name}-#{SecureRandom.uuid}"
  )

  Entry.create!(
    account: system,
    ledger_transaction: transaction,
    amount_cents: -balance_cents,
    entry_type: "debit"
  )

  Entry.create!(
    account: account,
    ledger_transaction: transaction,
    amount_cents: balance_cents,
    entry_type: "credit"
  )

  system.update!(
    balance_cents:
      system.balance_cents - balance_cents
  )

  account
end

  path '/api/v1/transfers' do

    post 'Creates money transfer' do

      tags 'Transfers'

      consumes 'application/json'
      produces 'application/json'

      parameter name: :'Idempotency-Key',
          in: :header,
          type: :string,
          required: false

      parameter name: :transfer, in: :body, schema: {
        type: :object,
        properties: {
          from_account_id: { type: :integer },
          to_account_id: { type: :integer },
          amount_cents: { type: :integer },
          reference: { type: :string }
        },
        required: [
          'from_account_id',
          'to_account_id',
          'amount_cents',
          'reference'
        ]
      }

      let!(:alice) do
        create_account_with_balance(
        name: "Alice",
        currency: "USD",
        balance_cents: 100_000
        )
      end

      let!(:bob) do
        create_account_with_balance(
        name: "Bob",
        currency: "USD",
        balance_cents: 50_000
        )
      end

      let(:transfer) do
        {
          from_account_id: alice.id,
          to_account_id: bob.id,
          amount_cents: 10_000,
          reference: "swagger-transfer-001"
        }
      end

      response '201', 'transfer created' do

        let('Idempotency-Key') { 'swagger-key-001' }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['status']).to eq('success')
        end
      end

      response '400', 'missing idempotency key' do

        let(:'Idempotency-Key') { nil }

        let(:transfer) do
          {
            from_account_id: alice.id,
            to_account_id: bob.id,
            amount_cents: 10_000,
            reference: "swagger-transfer-002"
          }
        end

        run_test!
      end
    end
  end
end
