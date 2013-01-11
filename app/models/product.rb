class Product < ActiveRecord::Base
  establish_connection(Rails.configuration.database_configuration['mlcs_production'])
  set_table_name 'iapproduct'

  has_many :purchases, inverse_of: :product, primary_key: 'app_store_id'

  def self.ios_unlimited
    Product.find(5)
  end

  def self.android_unlimited
    Product.find(22)
  end

  def self.ios_yearlies
    Product.where("app_store_id LIKE '%1year%' and platform='ios'").all
  end

  def self.android_yearlies
    Product.where("app_store_id LIKE '%1year%' and platform='android'").all
  end

end