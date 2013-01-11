class Purchase < ActiveRecord::Base
  establish_connection(Rails.configuration.database_configuration['mlcs_production'])

  has_one :product, inverse_of: :purchases, foreign_key: 'app_store_id', primary_key: 'product_id'

  # def self.test
  #   platform = 'ios'
  #   connection.execute("select 
  #     iapproduct.platform, count(purchases.price) as price, 
  #     sum(purchases.price) as total, 
  #     purchases.modified 
  #     from 
  #     iapproduct, purchases 
  #     where 
  #     iapproduct.app_store_id = purchases.product_id and 
  #     CAST(purchases.price  AS DECIMAL) = CAST(1.99 AS DECIMAL) and 
  #     iapproduct.platform='"+platform+"' and 
  #     modified is not null");
  # end

  

end