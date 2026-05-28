require "rails_helper"

RSpec.describe Category::CreateCategoryService do
    before do
      CategorizedTransaction.delete_all
      Category.delete_all
      Wallet.delete_all
      Entry.delete_all
      LedgerTransaction.delete_all
      Account.delete_all
      User.delete_all
    end 

  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  describe ".call" do
    it "creates expense category" do
      category =
        Category::CreateCategoryService.call(
          user: user,
          name: "Food",
          category_type: "expense"
        )

      expect(category.name).to eq("Food")
      expect(category.category_type)
        .to eq("expense")

      expect(Category.count).to eq(1)
    end

    it "normalizes category names" do
      category =
        Category::CreateCategoryService.call(
          user: user,
          name: "   food   ",
          category_type: "expense"
        )

      expect(category.name).to eq("Food")
    end

    it "prevents duplicate categories" do
      Category::CreateCategoryService.call(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      expect do
        Category::CreateCategoryService.call(
          user: user,
          name: " food ",
          category_type: "expense"
        )
      end.to raise_error(
        "Category already exists"
      )

      expect(Category.count).to eq(1)
    end

    it "allows same name for different types" do
      Category::CreateCategoryService.call(
        user: user,
        name: "Salary",
        category_type: "income"
      )

      category =
        Category::CreateCategoryService.call(
          user: user,
          name: "Salary",
          category_type: "expense"
        )

      expect(category.category_type)
        .to eq("expense")

      expect(Category.count).to eq(2)
    end

    it "rejects invalid category type" do
      expect do
        Category::CreateCategoryService.call(
          user: user,
          name: "Crypto",
          category_type: "investment"
        )
      end.to raise_error(
        "Invalid category type"
      )
    end
  end
end
