class HomeController < ApplicationController

  def index
    @stats = []
    # @stats << ProductsHelper.stats_from_product(Product.ios_unlimited)
    # @stats << ProductsHelper.stats_from_products(Product.ios_yearlies)
    # @stats << ProductsHelper.stats_from_product(Product.android_unlimited)
    # @stats << ProductsHelper.stats_from_products(Product.android_yearlies)
  end

  def hours
    # @purchases = Purchase.search(params)
    @hours = [Hour.search(params).first]
  end

end