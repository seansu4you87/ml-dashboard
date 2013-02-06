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

    @getPurchaseData()

  getPurchaseData: (page = 1) ->
    console.log "getting page #{page}"
    @$http(
      method: 'GET'
      url:    "http://localhost:3000/purchases.json?page=#{page}"
    ).
    success((data) =>
      console.log "got purchase data! #{data.length} purchases from #{data[0].id} to #{data[data.length - 1].id}"
      @$scope.data = @analyzePurchaseData(data)
      console.log @$scope.data
      @$scope.success = "Yes"

      @$scope.page += 1
      if data.length and page < 1
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

    # created formatted data
    purchases = @$scope.purchases
    purchases.sort (a, b) -> 
      if a.date > b.date
        return -1
      else 
        return 1

    date0 = purchases[purchases.length - 1].date
    dateN = purchases[0].date

    days = Math.floor((dateN - date0) / 86400000) + 1

    products = Product.productArray

    formattedData = []
    formattedData.length = products.length
    for i in [0...formattedData.length] by 1
      formattedData[i] = []
      formattedData[i].length = days
      for j in [0...formattedData[i].length] by 1
        formattedData[i][j] = 
          x: j,
          y: 0

    for purchase in purchases
      date = purchase.date
      curDay = Math.floor (date - date0) / 86400000
      formattedData[purchase.product.index][curDay].y += 1
      formattedData[0][curDay].date = date.getUTCMonth() + "/" + date.getUTCDate()

    formattedData[0][0].product = "ios_yearly"
    formattedData[1][0].product = "ios_unlimited"
    formattedData[2][0].product = "android_yearly"
    formattedData[3][0].product = "android_unlimited"

    # new formatted data method
    realData = []
    realData.length = products.length
    for i in [0...realData.length] by 1
      realData[i] = @yearOfWeekBuckets()

    for purchase in purchases
      date0 = realData[0][0].startDate
      date = purchase.date
      week = Math.floor (date - date0) / (1000 * 60 * 60 * 24 * 7)
      bucket = realData[purchase.product.index][week]
      bucket.product = purchase.product if bucket.product == null
      bucket.purchases.push purchase
      # console.log "#{date} is in week #{week}: #{realData[0][week].startDate} to #{realData[0][week].endDate}"

    console.log realData

    for productArray in realData
      i = 0
      for bucket in productArray
        bucket.x = i
        bucket.y = bucket.purchases.length
        i++

    return realData

    # return
    return formattedData

  yearOfWeekBuckets: ->
    endDate = new Date()
    startDate = new Date(endDate.getFullYear() - 1, endDate.getMonth(), endDate.getDate())
    currentDate = startDate

    console.log (endDate - startDate)/(1000 * 60 * 60 * 24 * 365.25)

    i = 0
    buckets = []
    createBucket = ->
      startOfWeekDate = new Date(currentDate.getTime())
      currentDate.setDate(currentDate.getDate() + 7)
      endOfWeekDate = new Date(currentDate - 1000)
      bucket = new TimeBucket(startOfWeekDate, endOfWeekDate, null)
      buckets.push bucket
      # console.log "Week #{i}: #{bucket}"
      # console.log "Week #{i}: #{startOfWeekDate} to #{endOfWeekDate}"
      i++

    createBucket() while currentDate <= endDate
    # console.log buckets
    buckets
      

@PurchaseController = PurchaseController