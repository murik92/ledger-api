class CategorizedTransaction < ApplicationRecord
  belongs_to :user

  belongs_to :ledger_transaction

  belongs_to :category

  scope :expenses, -> {
    where(transaction_type: "expense")
  }

  scope :income, -> {
    where(transaction_type: "income")
  }

  enum transaction_type: {
    expense: "expense",
    income: "income"
  }, _prefix: true

  validates :transaction_type,
            presence: true

  validate :validate_category_type_matches_transaction
  validate :validate_category_ownership

  def expense?
    transaction_type_expense?
  end

  def income?
    transaction_type_income?
  end

  private

  def validate_category_type_matches_transaction
    return if category.nil?

    if transaction_type != category.category_type
      errors.add(
        :category,
        "type must match transaction type"
      )
    end
  end

  def validate_category_ownership
    return if category.nil?

    if category.user_id != user_id
      errors.add(
        :category,
        "must belong to transaction user"
      )
    end
  end
end
