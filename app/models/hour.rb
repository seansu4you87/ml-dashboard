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
      hour:     @hour.to_s,
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
      if doc
        remove doc.id
        puts "\n"
        puts "switching max_purchase_id #{doc.max_purchase_id} for #{max_purchase_id}"
        puts "\n"
      end

      store max_purchase_id: max_purchase_id
    end
  end

  def self.get_hour_doc(hour)
    s = tire.search(per_page: 600 * 1000) do
      query do
        boolean do
          must { term :hour,     hour.hour.to_s }
          must { term :platform, hour.platform } if hour.platform
          must { term :price,    hour.price } if hour.price
          must { term :restored, true } if hour.restored
        end
      end
    end

    s.results.each do |r|
      if hour.price == r.price and hour.platform == r.platform and hour.hour.to_s == r.hour
        return r
      end
    end

    # s.results.each { |r| puts "#{r.hour.to_s}: #{r._score.to_s[0...8]} #{r.platform.to_s[0...3]}_#{r.price} #{r.count}" }
    nil
  end

  def self.set_hour_doc(hour)
    hour_doc = Hour.get_hour_doc(hour)
    hour.count += hour_doc.count

    Tire.index 'hours' do
      remove hour_doc.id
      store hour
    end
  end

  def self.hour_from_purchase(purchase)
    datetime = DateTime.new(purchase.modified.year, purchase.modified.month, purchase.modified.day, purchase.modified.hour)
    Hour.new(datetime, purchase.platform, purchase.price, purchase.restored)
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
        if Hour.get_hour_doc(hour).nil?
          store hour
        else
          Hour.set_hour_doc(hour)
        end
      end

      Hour.set_max_purchase_id(max_purchase_id)

      puts "\n#{Time.now}: max_purchase_id: #{max_purchase_id}\n"
      puts "\n#{Time.now}: hours summary stored in ElasticSearch!\n"

      refresh
    end
  end

end