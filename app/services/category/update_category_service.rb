class Category::UpdateCategoryService
  def self.call(
    category:,
    user:,
    name: nil,
    category_type: nil
  )

    unless category.owned_by?(user)
      raise "Access denied"
    end

    attrs = {}

    if name.present?
      attrs[:name] =
        Category::CreateCategoryService
          .normalize_name(name)
    end

    if category_type.present?
      Category::CreateCategoryService
        .validate_category_type!(category_type)

      attrs[:category_type] = category_type
    end

    category.update!(attrs)

    category
  end
end
