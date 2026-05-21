require 'swagger_helper'

RSpec.describe 'API V1 Transfers', type: :request do
  path '/api/v1/transfers' do
    post 'Create transfer' do
      tags 'Transfers'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true

      parameter name: :transfer,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    from_account_id: { type: :integer },
                    to_account_id: { type: :integer },
                    amount_cents: { type: :integer },
                    idempotency_key: { type: :string }
                  },
                  required: %w[
                    from_account_id
                    to_account_id
                    amount_cents
                    idempotency_key
                  ]
                }

      let(:user) do
        User.create!(
        email: Faker::Internet.unique.email,
         password: 'password123'
        )
      end

      let!(:from_account) do
        user.accounts.create!(
          name: 'Main Account',
          currency: 'USD',
          balance_cents: 10_000,
          opening_balance_cents: 10_000
        )
      end

      let!(:to_account) do
        user.accounts.create!(
          name: 'Savings Account',
          currency: 'USD',
          balance_cents: 0,
          opening_balance_cents: 0
        )
      end

      let(:token) do
        JsonWebToken.encode(user_id: user.id)
      end

      let(:Authorization) do
        "Bearer #{token}"
      end

      response '201', 'transfer created' do
        let(:transfer) do
          {
            from_account_id: from_account.id,
            to_account_id: to_account.id,
            amount_cents: 1000,
            idempotency_key: SecureRandom.uuid
          }
        end

        run_test!
      end

      response '400', 'missing idempotency key' do
        let(:transfer) do
          {
            from_account_id: from_account.id,
            to_account_id: to_account.id,
            amount_cents: 1000
          }
        end

        run_test!
      end
    end
  end
end
