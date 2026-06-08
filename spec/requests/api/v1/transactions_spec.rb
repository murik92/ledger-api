require "rails_helper"

RSpec.describe "Transactions API", type: :request do
  before do
    CategorizedTransaction.delete_all
    Category.delete_all
    Wallet.delete_all
    Entry.delete_all
    LedgerTransaction.delete_all
    Account.delete_all
    RefreshToken.delete_all
    User.delete_all
  end

  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  let(:token) do
    JsonWebToken.encode(
      user_id: user.id
    )
  end

  let(:headers) do
    {
      "Authorization" => "Bearer #{token}"
    }
  end

  let!(:expense_category) do
    Category.create!(
      user: user,
      name: "Food",
      category_type: "expense"
    )
  end

  let!(:income_category) do
    Category.create!(
      user: user,
      name: "Salary",
      category_type: "income"
    )
  end

  describe "GET /api/v1/transactions" do
    it "returns user transactions" do
      expense_tx = LedgerTransaction.create!(
        reference: SecureRandom.uuid,
        status: "completed",
        idempotency_key: SecureRandom.uuid,
        request_fingerprint: SecureRandom.uuid
      )

      income_tx = LedgerTransaction.create!(
        reference: SecureRandom.uuid,
        status: "completed",
        idempotency_key: SecureRandom.uuid,
        request_fingerprint: SecureRandom.uuid
      )

      CategorizedTransaction.create!(
        user: user,
        ledger_transaction: expense_tx,
        category: expense_category,
        transaction_type: "expense",
        note: "Lunch"
      )

      CategorizedTransaction.create!(
        user: user,
        ledger_transaction: income_tx,
        category: income_category,
        transaction_type: "income",
        note: "Monthly salary"
      )

      get "/api/v1/transactions",
          headers: headers

      expect(response)
        .to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["status"])
        .to eq("success")

      expect(body["data"].size)
        .to eq(2)
    end

    it "returns unauthorized without token" do
      get "/api/v1/transactions"

      expect(response)
        .to have_http_status(:unauthorized)
    end

    it "returns only current user transactions" do
      another_user =
        User.create!(
          email: "#{SecureRandom.uuid}@example.com",
          password: "password123"
        )

      another_category =
        Category.create!(
          user: another_user,
          name: "Private",
          category_type: "expense"
        )

      tx =
        LedgerTransaction.create!(
          reference: SecureRandom.uuid,
          status: "completed",
          idempotency_key: SecureRandom.uuid,
          request_fingerprint: SecureRandom.uuid
        )

      CategorizedTransaction.create!(
        user: another_user,
        ledger_transaction: tx,
        category: another_category,
        transaction_type: "expense",
        note: "Hidden"
      )

      get "/api/v1/transactions",
          headers: headers

      body = JSON.parse(response.body)

      expect(body["data"].size)
        .to eq(0)
    end
  end

  describe "GET /api/v1/transactions/:id" do
    let!(:transaction_record) do
        ledger_transaction =
        LedgerTransaction.create!(
            reference: SecureRandom.uuid,
            status: "completed",
            idempotency_key: SecureRandom.uuid,
            request_fingerprint: SecureRandom.uuid
        )

        CategorizedTransaction.create!(
        user: user,
        ledger_transaction: ledger_transaction,
        category: expense_category,
        transaction_type: "expense",
        note: "Lunch"
        )
    end

    it "returns transaction details" do
        get "/api/v1/transactions/#{transaction_record.id}",
            headers: headers

        expect(response)
        .to have_http_status(:ok)

        body = JSON.parse(response.body)

        expect(body["status"])
        .to eq("success")

        expect(
        body["data"]["transaction_type"]
        ).to eq("expense")

        expect(
        body["data"]["category"]
        ).to eq("Food")

        expect(
        body["data"]["note"]
        ).to eq("Lunch")
    end

    it "returns unauthorized without token" do
        get "/api/v1/transactions/#{transaction_record.id}"

        expect(response)
        .to have_http_status(:unauthorized)
    end

    it "does not allow access to another user's transaction" do
        another_user =
        User.create!(
            email: "#{SecureRandom.uuid}@example.com",
            password: "password123"
        )

        another_category =
        Category.create!(
            user: another_user,
            name: "Private",
            category_type: "expense"
        )

        another_ledger_transaction =
        LedgerTransaction.create!(
            reference: SecureRandom.uuid,
            status: "completed",
            idempotency_key: SecureRandom.uuid,
            request_fingerprint: SecureRandom.uuid
        )

        another_transaction =
        CategorizedTransaction.create!(
            user: another_user,
            ledger_transaction: another_ledger_transaction,
            category: another_category,
            transaction_type: "expense",
            note: "Secret"
        )

        get "/api/v1/transactions/#{another_transaction.id}",
            headers: headers

        expect(response)
        .to have_http_status(:unprocessable_content)
    end
  end

    describe "GET /api/v1/transactions filtering" do
    let!(:food_transaction) do
      ledger_transaction =
        LedgerTransaction.create!(
          reference: SecureRandom.uuid,
          status: "completed",
          idempotency_key: SecureRandom.uuid,
          request_fingerprint: SecureRandom.uuid
        )

      CategorizedTransaction.create!(
        user: user,
        ledger_transaction: ledger_transaction,
        category: expense_category,
        transaction_type: "expense",
        note: "Burger"
      )
    end

    let!(:salary_transaction) do
      ledger_transaction =
        LedgerTransaction.create!(
          reference: SecureRandom.uuid,
          status: "completed",
          idempotency_key: SecureRandom.uuid,
          request_fingerprint: SecureRandom.uuid
        )

      CategorizedTransaction.create!(
        user: user,
        ledger_transaction: ledger_transaction,
        category: income_category,
        transaction_type: "income",
        note: "Salary"
      )
    end

    it "filters by transaction_type" do
      get "/api/v1/transactions",
          params: {
            transaction_type: "expense"
          },
          headers: headers

      expect(response)
        .to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["data"].size)
        .to eq(1)

      expect(
        body["data"].first["transaction_type"]
      ).to eq("expense")
    end

    it "filters by category_id" do
      get "/api/v1/transactions",
          params: {
            category_id: expense_category.id
          },
          headers: headers

      expect(response)
        .to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["data"].size)
        .to eq(1)

      expect(
        body["data"].first["category"]
      ).to eq("Food")
    end

    it "combines multiple filters" do
      get "/api/v1/transactions",
          params: {
            transaction_type: "income",
            category_id: income_category.id
          },
          headers: headers

      expect(response)
        .to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["data"].size)
        .to eq(1)

      expect(
        body["data"].first["transaction_type"]
      ).to eq("income")
    end
  end

end
