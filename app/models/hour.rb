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

end