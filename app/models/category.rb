class Category < ApplicationRecord
  belongs_to :user

  has_many :categorized_transactions,
         dependent: :restrict_with_exception
         
  def owned_by?(user)
    self.user == user
  end

  def expense_category?
    category_type_expense?
  end

  def income_category?
    category_type_income?
  end

  enum category_type: {
    expense: "expense",
    income: "income"
  }, _prefix: true

  validates :name,
            presence: true,
            uniqueness: {
              scope: [
                :user_id,
                :category_type
              ]
            }

  validates :category_type,
            presence: true
end
