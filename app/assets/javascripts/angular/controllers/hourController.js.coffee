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

    @$scope.$watch 'iosUnlimitedSelected', (newVal, oldVal) =>
      @setDataOnScope()

    @$scope.$watch 'androidYearlySelected', (newVal, oldVal) =>
      @setDataOnScope()

    @$scope.$watch 'androidUnlimitedSelected', (newVal, oldVal) =>
      @setDataOnScope()

    # push empty buckets into data
    @$scope.data = []
    for productName in Hour.productArray
      @$scope.data.push @yearOfWeekBuckets(productName)



    @getHourData()

  setDataOnScope: ->
    data = [@yearOfWeekBuckets(), @yearOfWeekBuckets(), @yearOfWeekBuckets(), @yearOfWeekBuckets()]
    
    data[0] = @$scope.iosYearlyData           if @$scope.iosYearlySelected
    data[1] = @$scope.iosUnlimitedData        if @$scope.iosUnlimitedSelected
    data[2] = @$scope.androidYearlyData       if @$scope.androidYearlySelected
    data[3] = @$scope.androidUnlimitedData    if @$scope.androidUnlimitedSelected

    @$scope.data = data

  getHourData: (page = 1) ->
    @$http.get("http://10.177.134.211:3001/hours.json?page=#{page}")
    .success((data) =>
      @analyzeHourData(data)
      @$scope.success = "Yes"
    )
    .error((data, status) ->
      @$scope.success = "No"
      @$scope.error = status
    )

  analyzeHourData: (hourData) ->
    for hourDatum in hourData
      continue if hourDatum.platform == null

      hour = new Hour(hourDatum)

      # if hour.platform == undefined
      #   console.log hourDatum

      @$scope.hours.push hour
      @$scope.iosYearly         += hour.count if hour.productName == "ios_yearly"
      @$scope.iosUnlimited      += hour.count if hour.productName == "ios_unlimited"
      @$scope.androidYearly     += hour.count if hour.productName == "android_yearly"
      @$scope.androidUnlimited  += hour.count if hour.productName == "android_unlimited"
        
    allData = []
    for productName in Hour.productArray
      allData.push @yearOfWeekBuckets(productName)

    for hour in @$scope.hours
      date = hour.hour
      properBucket = null
      
      console.log "index: #{Hour.productArray.indexOf hour.productName}"
      for bucket in allData[Hour.productArray.indexOf hour.productName]
        if date >= bucket.startDate and date < bucket.endDate
          properBucket = bucket
          continue

      if properBucket == null
        console.log "IMPROPER BUCKET! FIX THIS!"
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

    @$scope.iosYearlyData         = allData[Hour.productArray.indexOf "ios_yearly"]
    @$scope.iosUnlimitedData      = allData[Hour.productArray.indexOf "ios_unlimited"]
    @$scope.androidYearlyData     = allData[Hour.productArray.indexOf "android_yearly"]
    @$scope.androidUnlimitedData  = allData[Hour.productArray.indexOf "android_unlimited"]

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