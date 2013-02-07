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
      if data.length and @$scope.page <= 2
        @getPurchaseData(@$scope.page)
    ).
    error((data, status) ->
      @$scope.success = "No"
      @$scope.error = status
    )

  analyzePurchaseData: (purchaseData) ->
    for purchaseDatum in purchaseData
      continue if purchaseDatum.platform == null

      purchase = new Purchase(purchaseDatum)
      @$scope.purchases.push purchase

      if purchase.product.name == "ios_yearly"
        @$scope.ios_yearly += 1
      else if purchase.product.name == "ios_unlimited"
        @$scope.ios_unlimited += 1
      else if purchase.product.name == "android_yearly"
        @$scope.android_yearly += 1
      else if purchase.product.name == "android_unlimited"
        @$scope.android_unlimited += 1
      else
        alert "#{purchase.product.name} is an invalid product name"

    @$scope.purchaseCount = @$scope.purchases.length

    
    # format data
    realData = @$scope.data
    realData = []
    for productName in Product.productArray
      realData.push @yearOfWeekBuckets(productName)

    for purchase in @$scope.purchases
      date = purchase.date
      properBucket = null
      for bucket in realData[purchase.product.index]
        if date >= bucket.startDate and date < bucket.endDate
          properBucket = bucket
          continue
      properBucket.purchases.push purchase

    # console.log realData

    for productArray in realData
      i = 0
      for bucket in productArray
        bucket.x = i
        bucket.y = bucket.purchases.length
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