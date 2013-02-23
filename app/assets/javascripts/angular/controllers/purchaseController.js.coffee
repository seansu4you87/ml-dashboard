class Purchase
  constructor: (json) ->
    @product = new Product(json.platform, (Number)(json.price))
    @version = json.version
    @date = new Date(json.modified)



class Product
  @productArray = ["ios_yearly", "ios_unlimited", "android_yearly", "android_unlimited"]
  
  constructor: (platform, price) ->
    @platform = platform
    @price = (Number)(price)
    @name = @deriveName()
    @index = Product.productArray.indexOf @name

  deriveName: ->
    if @platform == "ios"
      if @price == 1.99
        return "ios_yearly"
      else if @price == 5.99
        return "ios_unlimited"
    else if @platform == "android"
      if @price == 1.99
          return "android_yearly"
        else if @price == 5.99
          return "android_unlimited"
    "unknown"



class TimeBucket
  constructor: (startDate, endDate, product) ->
    @startDate = startDate
    @endDate = endDate
    @product = product
    @purchases = []

class Hour
  constructor: (json) ->
    @hour     = new Date(json.hour)
    @platform = json.platform
    @price    = (Number)(json.price)
    @restored = json.restored
    @count    = json.count

    @productName = @deriveName()

  deriveName: ->
    if @platform == "ios"
      if @price == 1.99
        return "ios_yearly"
      else if @price == 5.99
        return "ios_unlimited"
    else if @platform == "android"
      if @price == 1.99
          return "android_yearly"
        else if @price == 5.99
          return "android_unlimited"
    "unknown"


class PurchaseController
  constructor: (@$scope, @$http) ->
    @$scope.success = "Waiting"

    @$scope.ios_yearly = 0
    @$scope.ios_unlimited = 0
    @$scope.android_yearly = 0
    @$scope.android_unlimited = 0
    
    @$scope.page = 1
    @$scope.purchases = []

    @$scope.endDate = new Date()
    @$scope.startDate = new Date(@$scope.endDate.getFullYear() - 1, @$scope.endDate.getMonth(), @$scope.endDate.getDate())
    @$scope.bucketLength = 7 #days

    @$scope.iOSYearly = true
    @$scope.iOSUnlimited = true
    @$scope.androidYearly = true
    @$scope.androidUnlimited = true

    @$scope.$watch 'iOSYearly', (newVal, oldVal) =>
      @hideShowProduct(newVal, oldVal, "ios_yearly")

    @$scope.$watch 'iOSUnlimited', (newVal, oldVal) =>
      @hideShowProduct(newVal, oldVal, "ios_unlimited")

    @$scope.$watch 'androidYearly', (newVal, oldVal) =>
      @hideShowProduct(newVal, oldVal, "android_yearly")

    @$scope.$watch 'androidUnlimited', (newVal, oldVal) =>
      @hideShowProduct(newVal, oldVal, "android_unlimited")

    @$scope.data = []
    for productName in Product.productArray
      @$scope.data.push @yearOfWeekBuckets(productName)

    for productArray in @$scope.data
      i = 0
      for bucket in productArray
        bucket.x = i
        bucket.y = bucket.purchases.length
        i++

    @getPurchaseData()

  hideShowProduct: (newVal, oldVal, productName) ->
    return if newVal == oldVal
    height = 479.5

    y = d3.scale.linear()
          .domain([0, 10000])
          .range([0, height])

    barHeight = (d) =>
      if newVal 
        console.log y(@$scope.data[d.product][d.index].y)
        return y(@$scope.data[d.product][d.index].y)
      else
        return 0

    d3.select("g.layer##{productName}").selectAll("rect")
      .transition()
      .duration(500)
      .attr("y", (d) -> height - barHeight(d))
      .attr("height", barHeight)

  getPurchaseData: (page = 1) ->
    # console.log "getting page #{page}"
    @$http(
      method: 'GET'
      url:    "http://localhost:3000/purchases.json?page=#{page}"
    ).
    success((data) =>
      # console.log "got purchase data! #{data.length} purchases from #{data[0].id} to #{data[data.length - 1].id}"
      @$scope.data = @analyzePurchaseData(data)
      # console.log @$scope.data
      @$scope.success = "Yes"

      @$scope.page += 1
      if data.length and @$scope.page <= 1
        @getPurchaseData(@$scope.page)
    ).
    error((data, status) ->
      @$scope.success = "No"
      @$scope.error = status
    )

  analyzePurchaseData: (purchaseData) ->
    for purchaseDatum in purchaseData
      continue if purchaseDatum.platform == null

      hour = new Hour(purchaseDatum)
      @$scope.purchases.push hour

      if hour.productName == "ios_yearly"
        @$scope.ios_yearly += hour.count
      else if hour.productName == "ios_unlimited"
        @$scope.ios_unlimited += hour.count
      else if hour.productName == "android_yearly"
        @$scope.android_yearly += hour.count
      else if hour.productName == "android_unlimited"
        @$scope.android_unlimited += hour.count
      else
        alert "#{hour.productName} is an invalid product name"

    @$scope.purchaseCount = @$scope.ios_yearly + 
                            @$scope.ios_unlimited + 
                            @$scope.android_yearly + 
                            @$scope.android_unlimited

    
    # format data
    # realData = @$scope.data
    realData = []
    for productName in Product.productArray
      realData.push @yearOfWeekBuckets(productName)

    for hour in @$scope.purchases
      date = hour.hour
      properBucket = null
      for bucket in realData[Product.productArray.indexOf hour.productName]
        if date >= bucket.startDate and date < bucket.endDate
          properBucket = bucket
          continue

      if properBucket == null
        console.log realData[Product.productArray.indexOf hour.productName]
        console.log date
      properBucket.purchases.push hour

    # console.log realData

    for productArray in realData
      i = 0
      for bucket in productArray
        bucket.x = i
        total = 0
        for hour in bucket.purchases
          total += hour.count
        bucket.y = total
        i++

    return realData

  yearOfWeekBuckets: (product = null) ->
    endDate = new Date(@$scope.endDate)
    startDate = new Date(@$scope.startDate)

    buckets = []
    currentDate = startDate
    createBucket = =>
      startOfWeekDate = new Date(currentDate.getTime())
      currentDate.setDate(currentDate.getDate() + @$scope.bucketLength)
      endOfWeekDate = new Date(currentDate - 1000)
      bucket = new TimeBucket(startOfWeekDate, endOfWeekDate, product)
      buckets.push bucket

    createBucket() while currentDate <= endDate
    buckets
      

@PurchaseController = PurchaseController