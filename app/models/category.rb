class Category < ApplicationRecord
  belongs_to :user

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
