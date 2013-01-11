module ProductsHelper

  def self.type_from_product(product)
    return 'Unlimited'  if product.app_store_id.include? 'unlimited'
    return 'Yearly'     if product.app_store_id.include? 'year'
  end

  def self.gross_revenue_from_product(product)
    product.purchases.count * product.price
  end

  def self.stats_from_product(product)
    self.stats_from_products([product])
  end

  def self.stats_from_products(products)
    product = products.first
    stats = {
      platform: product.platform,
      type:     self.type_from_product(product),
      price:    product.price,
      count:    0,
      revenue:  0
    }
    products.each do |product|
      raise 'different platforms' if stats[:platform] != product.platform
      raise 'different types'     if stats[:type] != self.type_from_product(product)
      raise 'different prices'    if stats[:price] != product.price

      stats[:count] += product.purchases.count
    end
    stats[:revenue] = stats[:count] * stats[:price]
    stats
  end

end