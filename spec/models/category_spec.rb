require "rails_helper"

RSpec.describe Category, type: :model do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  describe "associations" do
    it "belongs to user" do
      category = Category.new(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      expect(category.user).to eq(user)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      category = Category.new(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      expect(category).to be_valid
    end

    it "requires name" do
      category = Category.new(
        user: user,
        category_type: "expense"
      )

      expect(category).not_to be_valid

      expect(category.errors[:name])
        .to include("can't be blank")
    end

    it "requires category_type" do
      category = Category.new(
        user: user,
        name: "Food"
      )

      expect(category).not_to be_valid

      expect(category.errors[:category_type])
        .to include("can't be blank")
    end

    it "prevents duplicate category names per type" do
      Category.create!(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      duplicate = Category.new(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      expect(duplicate).not_to be_valid

      expect(duplicate.errors[:name])
        .to include("has already been taken")
    end

    it "allows same name for different category type" do
      Category.create!(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      income_category = Category.new(
        user: user,
        name: "Food",
        category_type: "income"
      )

      expect(income_category).to be_valid
    end
  end

  describe "enums" do
    it "supports expense category" do
      category = Category.new(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      expect(
        category.category_type_expense?
      ).to eq(true)
    end

    it "supports income category" do
      category = Category.new(
        user: user,
        name: "Salary",
        category_type: "income"
      )

      expect(
        category.category_type_income?
      ).to eq(true)
    end
  end
end
