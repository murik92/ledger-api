require "rails_helper"

RSpec.describe Transactions::CreateExpenseTransactionService do
let(:user) do
User.create!(
email: "#{SecureRandom.uuid}@example.com",
password: "password123"
)
end

let(:wallet) do
Wallet::CreateWalletService.call(
user: user,
currency: "USD",
name: "Main wallet"
)
end

let(:expense_category) do
Category.create!(
user: user,
name: "Food",
category_type: "expense"
)
end

let(:income_category) do
Category.create!(
user: user,
name: "Salary",
category_type: "income"
)
end

before do
AccountFundingService.call(
account: wallet.account,
amount_cents: 10_000,
idempotency_key: SecureRandom.uuid
)
end

describe ".call" do
it "creates double-entry ledger entries" do
result = described_class.call(
user: user,
wallet: wallet,
category: expense_category,
amount_cents: 5_000,
note: "Dinner",
idempotency_key: SecureRandom.uuid
)

  entries =
    Entry.where(
      ledger_transaction: result.ledger_transaction
    )

  expect(entries.count).to eq(2)

  expect(
    entries.sum(:amount_cents)
  ).to eq(0)

  expect(
    entries.pluck(:entry_type)
  ).to contain_exactly(
    "debit",
    "credit"
  )
end

it "creates expense categorized transaction" do
  result = described_class.call(
    user: user,
    wallet: wallet,
    category: expense_category,
    amount_cents: 5_000,
    note: "Dinner",
    idempotency_key: SecureRandom.uuid
  )

  expect(result.transaction_type)
    .to eq("expense")

  expect(result.note)
    .to eq("Dinner")

  expect(result.category)
    .to eq(expense_category)

  expect(result.user)
    .to eq(user)
end

it "creates ledger transaction" do
  result = described_class.call(
    user: user,
    wallet: wallet,
    category: expense_category,
    amount_cents: 5_000,
    note: "Dinner",
    idempotency_key: SecureRandom.uuid
  )

  expect(
    result.ledger_transaction
  ).to be_present

  expect(
    result.ledger_transaction
  ).to be_a(LedgerTransaction)
end

it "rejects income category" do
  expect do
    described_class.call(
      user: user,
      wallet: wallet,
      category: income_category,
      amount_cents: 5_000,
      note: "Invalid",
      idempotency_key: SecureRandom.uuid
    )
  end.to raise_error(
    ArgumentError,
    "Category must be expense type"
  )
end

it "does not create duplicate expense with same idempotency key" do
  key = "expense-key-001"

  first_result = described_class.call(
    user: user,
    wallet: wallet,
    category: expense_category,
    amount_cents: 5_000,
    note: "Dinner",
    idempotency_key: key
  )

  second_result = described_class.call(
    user: user,
    wallet: wallet,
    category: expense_category,
    amount_cents: 5_000,
    note: "Dinner",
    idempotency_key: key
  )

  expect(first_result.id)
    .to eq(second_result.id)

  expect(
    LedgerTransaction.where(
      idempotency_key: key
    ).count
  ).to eq(1)

  expect(
    CategorizedTransaction.where(
      ledger_transaction_id:
        first_result.ledger_transaction_id
    ).count
  ).to eq(1)
end

end
end
