class TimeBucket
  constructor: (startDate, endDate, product) ->
    @startDate = startDate
    @endDate = endDate
    @product = product
    @hours = []

class Hour
  @productArray = ["ios_yearly", "ios_unlimited", "android_yearly", "android_unlimited"]

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


class HourController
  constructor: (@$scope, @$http) ->
    @$scope.success = "Waiting"
    
    @$scope.hours = []

    @$scope.endDate = new Date() # Today
    @$scope.startDate = new Date(@$scope.endDate.getFullYear() - 1, @$scope.endDate.getMonth(), @$scope.endDate.getDate()) # One Year Ago
    @$scope.bucketLength = 7 #days

    @$scope.iosYearly = 0
    @$scope.iosUnlimited = 0
    @$scope.androidYearly = 0
    @$scope.androidUnlimited = 0

    @$scope.iosYearlySelected = true
    @$scope.iosUnlimitedSelected = true
    @$scope.androidYearlySelected = true
    @$scope.androidUnlimitedSelected = true

    @$scope.$watch 'iosYearlyData', =>
      @setDataOnScope()

    @$scope.$watch 'iosUnlimitedData', =>
      @setDataOnScope()

    @$scope.$watch 'androidYearlyData', =>
      @setDataOnScope()

    @$scope.$watch 'androidUnlimitedData', =>
      @setDataOnScope()

    @$scope.$watch 'iosYearlySelected', (newVal, oldVal) =>
      @setDataOnScope()
      # @hideShowProduct(newVal, oldVal, "ios_yearly")

    @$scope.$watch 'iosUnlimitedSelected', (newVal, oldVal) =>
      @setDataOnScope()
      # @hideShowProduct(newVal, oldVal, "ios_unlimited")

    @$scope.$watch 'androidYearlySelected', (newVal, oldVal) =>
      @setDataOnScope()
      # @hideShowProduct(newVal, oldVal, "android_yearly")

    @$scope.$watch 'androidUnlimitedSelected', (newVal, oldVal) =>
      @setDataOnScope()
      # @hideShowProduct(newVal, oldVal, "android_unlimited")

    # push empty buckets into data
    @$scope.data = []
    for productName in Hour.productArray
      @$scope.data.push @yearOfWeekBuckets(productName)

    # set x positions of buckets
    for productArray in @$scope.data
      i = 0
      for bucket in productArray
        bucket.x = i
        bucket.y = bucket.hours.length
        i++

    @getHourData()

  setDataOnScope: ->
    console.log "resetting data on scope!"
    data = []
    if @$scope.iosYearlySelected
      data.push @$scope.iosYearlyData 
    else
      data.push @yearOfWeekBuckets()

    if @$scope.iosUnlimitedSelected
      data.push @$scope.iosUnlimitedData 
    else
      data.push @yearOfWeekBuckets()

    if @$scope.androidYearlySelected
      data.push @$scope.androidYearlyData
    else
      data.push @yearOfWeekBuckets()

    if @$scope.androidUnlimitedSelected
      data.push @$scope.androidUnlimitedData 
    else
      data.push @yearOfWeekBuckets()
      
    @$scope.data = data
    console.log @$scope.data

  hideShowProduct: (newVal, oldVal, productName) ->
    return if newVal == oldVal
    height = 479.5

    y = d3.scale.linear()
          .domain([0, 10000])
          .range([0, height])

    barHeight = (d) =>
      if newVal 
        # console.log y(@$scope.data[d.product][d.index].y)
        return y(@$scope.data[d.product][d.index].y)
      else
        return 0

    d3.select("g.layer##{productName}").selectAll("rect")
      .transition()
      .duration(500)
      .attr("y", (d) -> height - barHeight(d))
      .attr("height", barHeight)

  getHourData: (page = 1) ->
    @$http(
      method: 'GET'
      url:    "http://localhost:3000/hours.json?page=#{page}"
    ).
    success((data) =>
      @analyzeHourData(data)
      @$scope.success = "Yes"
    ).
    error((data, status) ->
      @$scope.success = "No"
      @$scope.error = status
    )

  analyzeHourData: (hourData) ->
    for hourDatum in hourData
      continue if hourDatum.platform == null

      hour = new Hour(hourDatum)
      @$scope.hours.push hour

      if hour.productName == "ios_yearly"
        @$scope.iosYearly += hour.count
      else if hour.productName == "ios_unlimited"
        @$scope.iosUnlimited += hour.count
      else if hour.productName == "android_yearly"
        @$scope.androidYearly += hour.count
      else if hour.productName == "android_unlimited"
        @$scope.androidUnlimited += hour.count
      else
        alert "#{hour.productName} is an invalid product name"

    @$scope.totalPurchases =  @$scope.iosYearly + 
                              @$scope.iosUnlimited + 
                              @$scope.androidYearly + 
                              @$scope.androidUnlimited

    
    allData = []
    for productName in Hour.productArray
      allData.push @yearOfWeekBuckets(productName)

    for hour in @$scope.hours
      date = hour.hour
      properBucket = null
      for bucket in allData[Hour.productArray.indexOf hour.productName]
        if date >= bucket.startDate and date < bucket.endDate
          properBucket = bucket
          continue

      if properBucket == null
        console.log allData[Hour.productArray.indexOf hour.productName]
        console.log date
      properBucket.hours.push hour

    for productArray in allData
      i = 0
      for bucket in productArray
        bucket.x = i
        total = 0
        for hour in bucket.hours
          total += hour.count
        bucket.y = total
        i++

    @$scope.iosYearlyData = allData[Hour.productArray.indexOf "ios_yearly"]
    @$scope.iosUnlimitedData = allData[Hour.productArray.indexOf "ios_unlimited"]
    @$scope.androidYearlyData = allData[Hour.productArray.indexOf "android_yearly"]
    @$scope.androidUnlimitedData = allData[Hour.productArray.indexOf "android_unlimited"]

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

    i = 0
    for bucket in buckets
      bucket.x = i
      bucket.y = bucket.hours.length
      i++
    buckets
      

@HourController = HourController