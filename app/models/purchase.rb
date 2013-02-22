class Purchase < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do 
    indexes :id,          type: 'integer'
    indexes :price,       type: 'double'
    indexes :version,     type: 'string'
    indexes :platform,    type: 'string'
    indexes :modified,    type: 'date'
  end

  establish_connection(Rails.configuration.database_configuration['mlcs_production'])

  has_one :product, inverse_of: :purchases, foreign_key: 'app_store_id', primary_key: 'product_id'

  def self.summarize
    Tire.index 'hours' do
      delete
      create

      purchases = Purchase.search({})
      summary = {}
      purchases.each do |p|
        date = DateTime.strptime(p.modified)
        hour = DateTime.new(date.year, date.month, date.day, date.hour)

        key = "#{hour.to_s} #{p.platform} #{p.price} #{p.restored}"

        if summary[key]
          summary[key].count += 1
        else
          summary[key] = Hour.new(hour, p.platform, p.price, p.restored)
          summary[key].count += 1
        end
      end

      summary.each do |key, hour|
        # puts hour
        store hour
      end

      refresh
    end
  end

  def self.search(params)
    # tire.search(load: true) do
    tire.search(page: params[:page], per_page: 600 * 1000) do
      query { string params[:q] } if params[:q].present?
      # query { string "android" }
      # query { all }
      # filter :range, published_on: { lte: Time.zone.now - 0.days }
    end
  end

  def to_indexed_json
    to_json(
      except: [
        'product_id', 
        'registration_id', 
        'slave_id', 
        'learn_pk',
        'device_id'
      ], 
      methods: [:platform]
    )
  end

  def platform
    self.product.platform if self.product
  end

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