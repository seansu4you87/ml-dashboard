class Hour
  include Tire::Model::Search
  extend  ActiveModel::Naming

  attr_reader   :hour, :platform, :price, :restored
  attr_accessor :count

  def initialize(hour, platform, price, restored)
    @hour       = hour
    @platform   = platform
    @price      = price
    @restored   = restored
    @count      = 0
  end

  def type
    'hour'
  end

  def to_indexed_json
    {
      hour:     @hour,
      platform: @platform,
      price:    @price,
      restored: @restored,
      count:    @count
    }.to_json
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

  def self.reset_index
    Tire.index 'hours' do
      delete
      create
    end
  end

  def self.all
    Hour.search({}).to_a
  end

  def self.purchase_count
    Hour.all.inject(0) { |sum, hour| sum + hour.count }
  end

  def self.get_max_purchase_id_doc
    s = Tire.search 'hours' do
      query do
        string 'max_purchase_id:*'
      end
    end

    s.results.first
  end

  def self.get_max_purchase_id
    max_purchase_id = 0

    max_purchase_id_doc = self.get_max_purchase_id_doc
    if max_purchase_id_doc
      max_purchase_id = max_purchase_id_doc.max_purchase_id
    end

    max_purchase_id
  end

  def self.set_max_purchase_id(max_purchase_id)
    doc = Hour.get_max_purchase_id_doc

    Tire.index 'hours' do
      remove doc.id if doc
      store max_purchase_id: max_purchase_id
    end
  end

  def self.get_hour_doc(hour)
    s = Tire.search 'hours' do
      query do
        term :hour, hour.hour.to_s
        term :platform, hour.platform.to_s
        term :price, hour.price.to_s
        term :restored, hour.restored.to_s
      end
    end

    s.results.to_a.first
  end

  def self.set_hour_doc(hour)
    hour_doc = Hour.get_hour_doc(hour)
    hour.count += hour_doc.count

    Tire.index 'hours' do
      remove hour_doc.id
      store hour
    end
  end

  def self.summarize
    Tire.index 'hours' do

      max_purchase_id = Hour.get_max_purchase_id
      puts "\n#{Time.now}: getting purchases with id > #{max_purchase_id}\n"
      
      purchases = Purchase.where("id > ?", max_purchase_id).limit(10 * 1000)

      if purchases.empty?
        puts "\n#{Time.now}: got 0 purchases\n"
      else
        puts "\n#{Time.now}: got #{purchases.count} purchases with ids between #{purchases.first.id} and #{purchases.last.id}\n"
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
          summary[key].count = 1
        end
      end

      puts "\n#{Time.now}: summarized!.  Now inserting into ElasticSearch\n"

      summary.each do |key, hour|
        # if Hour.get_hour_doc(hour).nil?
          store hour
        # else
          # Hour.set_hour_doc(hour)
        # end
      end

      Hour.set_max_purchase_id(max_purchase_id)

      puts "\n#{Time.now}: max_purchase_id: #{max_purchase_id}\n"
      puts "\n#{Time.now}: hours summary stored in ElasticSearch!\n"

      refresh
    end
  end

end