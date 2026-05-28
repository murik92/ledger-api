class Category::CreateCategoryService
  ALLOWED_CATEGORY_TYPES = %w[
    expense
    income
  ].freeze

  def self.call(
    user:,
    name:,
    category_type:
  )
    normalized_name =
      normalize_name(name)

    validate_category_type!(
      category_type
    )

    existing_category =
      Category.find_by(
        user: user,
        name: normalized_name,
        category_type: category_type
      )

    if existing_category
      raise(
        "Category already exists"
      )
    end

    Category.create!(
      user: user,
      name: normalized_name,
      category_type: category_type
    )
  end

  def self.normalize_name(name)
    name.strip.titleize
  end

  def self.validate_category_type!(
    category_type
  )
    unless ALLOWED_CATEGORY_TYPES.include?(
      category_type
    )
      raise(
        "Invalid category type"
      )
    end
  end
end
