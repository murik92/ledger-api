require "swagger_helper"

RSpec.describe "Categories API", type: :request do
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
      email: "swagger#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end

  let(:Authorization) do
    "Bearer #{JsonWebToken.encode(user_id: user.id)}"
  end

  path "/api/v1/categories" do
    get "List categories" do
      tags "Categories"
      produces "application/json"

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true

      response "200", "categories list" do
        before do
          Category.create!(user: user, name: "Food", category_type: "expense")
          Category.create!(user: user, name: "Salary", category_type: "income")
        end

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        run_test!
      end
    end

    post "Create category" do
      tags "Categories"
      consumes "application/json"
      produces "application/json"

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    category: {
                      type: :object,
                      properties: {
                        name: { type: :string },
                        category_type: { type: :string, enum: %w[income expense] }
                      },
                      required: %w[name category_type]
                    }
                  },
                  required: %w[category]
                }

      response "201", "category created" do
        let(:payload) do
          {
            category: {
              name: "Food",
              category_type: "expense"
            }
          }
        end

        run_test!
      end

      response "422", "duplicate category" do
        before do
          Category.create!(user: user, name: "Food", category_type: "expense")
        end

        let(:payload) do
          {
            category: {
              name: "Food",
              category_type: "expense"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/categories/{id}" do
    parameter name: :id,
              in: :path,
              type: :integer,
              required: true

    let!(:category) do
      Category.create!(
        user: user,
        name: "Food",
        category_type: "expense"
      )
    end

    let(:id) { category.id }

    patch "Update category" do
      tags "Categories"
      consumes "application/json"
      produces "application/json"

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    category: {
                      type: :object,
                      properties: {
                        name: { type: :string },
                        category_type: { type: :string, enum: %w[income expense] }
                      }
                    }
                  },
                  required: %w[category]
                }

      response "200", "category updated" do
        let(:payload) do
          {
            category: {
              name: "Restaurants"
            }
          }
        end

        run_test!
      end
    end

    delete "Delete category" do
      tags "Categories"
      produces "application/json"

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true

      response "200", "category deleted" do
        run_test!
      end
    end
  end
end
