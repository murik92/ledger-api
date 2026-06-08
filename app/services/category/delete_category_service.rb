class Category::DeleteCategoryService
  def self.call(
    category:,
    user:
  )
    unless category.owned_by?(user)
      raise "Access denied"
    end

    category.destroy!

    true
  end
end
