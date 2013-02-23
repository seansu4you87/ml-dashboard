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

  default_scope includes(:product)

  def self.summarize
    Tire.index 'hours' do

      s = Tire.search 'hours' do
        query do
          string 'max_purchase_id:*'
        end
      end

      max_purchase_id_doc = s.results.first
      max_purchase_id = 0
      if max_purchase_id_doc
        max_purchase_id = max_purchase_id_doc.max_purchase_id
      end

      puts "\n#{Time.now}: getting purchases with id > #{max_purchase_id}"
      
      purchases = Purchase.where("id > ?", max_purchase_id)

      if purchases.empty?
        puts "\n#{Time.now}: got 0 purchases"
      else
        puts "\n#{Time.now}: got #{purchases.count} purchases with ids between #{purchases.first.id} and #{purchases.last.id}"
      end

      summary = {}
      purchases.each do |p|
        max_purchase_id = p.id if p.id > max_purchase_id
        hour = DateTime.new(p.modified.year, p.modified.month, p.modified.day, p.modified.hour)

        key = "#{hour.to_s} #{p.platform} #{p.price} #{p.restored}"

        if summary[key]
          summary[key].count += 1
        else
          summary[key] = Hour.new(hour, p.platform, p.price, p.restored)
          summary[key].count += 1
        end
      end

      puts "\n#{Time.now}: summarized!"

      summary.each do |key, hour|
        s = Tire.search 'hours' do
          query do
            term :hour, hour.hour.to_s
            term :platform, hour.platform.to_s
            term :price, hour.price.to_s
            term :restored, hour.restored.to_s
          end
        end

        if s.results.to_a.empty?
          store hour
        else
          hour_doc = s.results.to_a.first
          count = hour_doc.count
          hour.count += count
          remove hour_doc.id
          store hour
        end

      end

      remove max_purchase_id_doc.id if max_purchase_id_doc
      store max_purchase_id: max_purchase_id

      puts "\n#{Time.now}: max_purchase_id: #{max_purchase_id}"

      puts "\n#{Time.now}: hours summary stored in ElasticSearch!"

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