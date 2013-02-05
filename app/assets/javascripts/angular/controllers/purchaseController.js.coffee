angular.module 'MLDashboard', []


class Purchase
  constructor: (json) ->
    @platform = json.platform
    @price = (Number)(json.price)
    @version = json.version
    @modified = new Date(json.modified)

  product: ->
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

  product_index: ->
    if @platform == "ios"
      if @price == 1.99
        return 0
      else if @price == 5.99
        return 1
    else if @platform == "android"
      if @price == 1.99
          return 2
        else if @price == 5.99
          return 3
    -1

class PurchaseController
  constructor: ($scope, $http) ->
    $scope.success = "Waiting"
    $scope.ios_yearly = 0
    $scope.ios_unlimited = 0
    $scope.android_yearly = 0
    $scope.android_unlimited = 0
    $scope.page = 1
    $scope.purchases = []

    $scope.getPurchaseData = (page = 1) ->
      console.log "getting page #{page}"
      $http(
        method: 'GET'
        url:    "http://localhost:3000/purchases.json?page=#{page}"
      ).
      success((data) ->
        console.log "got purchase data!"
        $scope.data = $scope.analyzePurchaseData(data)
        console.log $scope.data
        fjaoewijf
        $scope.success = "Yes"

        $scope.page += 1
        if data.length and page < 1
          $scope.getPurchaseData($scope.page)
      ).
      error((data, status) ->
        $scope.success = "No"
        $scope.error = status
      )

    $scope.analyzePurchaseData = (purchaseData) ->
      for purchaseDatum in purchaseData
        continue if purchaseDatum.platform == null

        purchase = new Purchase(purchaseDatum)
        $scope.purchases.push purchase

        if purchase.platform == "ios"
          if purchase.price == 1.99
            $scope.ios_yearly += 1
          else if purchase.price == 5.99
            $scope.ios_unlimited += 1
        else if purchase.platform == "android"
          if purchase.price == 1.99
            $scope.android_yearly += 1
          else if purchase.price == 5.99
            $scope.android_unlimited += 1

      # created formatted data

      $scope.purchases.sort (a, b) -> 
        if a.modified > b.modified
          return -1
        else 
          return 1

      date0 = $scope.purchases[$scope.purchases.length - 1].modified
      dateN = $scope.purchases[0].modified

      days = Math.floor((dateN - date0) / 86400000) + 1

      products = ['ios_yearly', 'ios_unlimited', 'android_yearly', 'android_unlimited']

      formattedData = []
      formattedData.length = products.length
      for i in [0...formattedData.length] by 1
        formattedData[i] = []
        formattedData[i].length = days
        for j in [0...formattedData[i].length] by 1
          formattedData[i][j] = 
            x: j,
            y: 0

      for purchase in $scope.purchases
        date = purchase.modified
        curDay = Math.floor (date - date0) / 86400000
        # console.log "#{date} - #{date0} = #{date - date0}"
        formattedData[purchase.product_index()][curDay].y += 1
        formattedData[0][curDay].date = date.getUTCMonth() + "/" + date.getUTCDate()

      formattedData[0][0].product = "ios_yearly"
      formattedData[1][0].product = "ios_unlimited"
      formattedData[2][0].product = "android_yearly"
      formattedData[3][0].product = "android_unlimited"

      # return stuff
      $scope.purchaseCount = $scope.purchases.length
      return formattedData

    $scope.getPurchaseData()

@PurchaseController = PurchaseController

angular.module('MLDashboard', []).directive('myDir', ->
  margin = 20
  width = 960
  height = 500 - 0.5 - margin
  color = d3.interpolateRgb("#f77", "#77f")

  restrict: 'E'
  terminal: true
  scope:
    val: "="
    grouped: "="
  link: (scope, element, attrs) ->

    vis = d3.select(element[0])
              .append("svg")
                .attr("width", width)
                .attr("height", height + margin + 100)

    scope.$watch 'val', (newVal, oldVal) ->
      vis.selectAll('*').remove();

      return unless newVal

      n = newVal.length
      m = newVal[0].length
      data = d3.layout.stack()(newVal)

      mx = m
      my = d3.max data, (d) -> 
        d3.max d, (d) ->
          d.y0 + d.y
      mz = d3.max data, (d) ->
        d3.max d, (d) ->
          d.y

      x = (d) -> d.x * width / mx
      y0 = (d) -> height - d.y0 * height / my
      y1 = (d) -> height - (d.y + d.y0) * height / my
      y2 = (d) -> d.y * height / mz

      layers = vis.selectAll("g.layer")
                  .data(data)
                  .enter()
                  .append("g")
                  .style("fill", (d, i) ->
                    color(i / (n - 1)))
                  .attr("class", "layer")

      bars = layers.selectAll("g.bar")
                        .data((d) -> d)
                        .enter()
                        .append("g")
                        .attr("class", "bar")
                        .attr("transform", (d) -> "translate(" + x(d) + ",0)")

      bars.append("rect")
          .attr("width", x({x: .9}))
          .attr("x", 0)
          .attr("y", height)
          .attr("height", 0)
          .transition()
          .delay((d, i) -> i * 10)
          .attr("y", y1)
          .attr("height", (d) -> y0(d) - y1(d))

      labels = vis.selectAll("text.label")
                  .data(data[0])
                  .enter()
                  .append("text")
                    .attr("class", "label")
                    .attr("x", x)
                    .attr("y", height + 6)
                    .attr("dx", x({x: .45}))
                    .attr("dy", ".71em")
                    .attr("text-anchor", "middle")
                    .text((d, i) -> d.date)

      keyText = vis.selectAll("text.key")
                    .data(data)
                    .enter()
                    .append("text")
                      .attr("class", "key")
                      .attr("y", (d, i) -> height  + 42 + 30 * (i%3))
                      .attr("x", (d, i) -> 155 * Math.floor(i/3) + 15)
                      .attr("dx", x({x: .45}))
                      .attr("dy", ".71em")
                      .attr("text-anchor", "left")
                      .text((d, i) -> d[0].product)

      keySwatches = vis.selectAll("rect.swatch")
                        .data(data)
                        .enter()
                        .append("rect")
                          .attr("class", "swatch")
                          .attr("width", 20)
                          .attr("height", 20)
                          .style("fill", (d, i) -> color(i / (n - 1)))
                          .attr("y", (d, i) -> height + 36 + 30 * (i%3))
                          .attr("x", (d, i) -> 155 * Math.floor(i/3))


      transitionGroup = ->
        transitionEnd = ->
          d3.select(this)
            .transition()
            .duration(500)
            .attr("y", (d) -> height - y2(d))
            .attr("height", y2)

        vis.selectAll("g.layer rect")
            .transition()
              .duration(500)
              .delay((d, i) -> (i % m) * 10)
              .attr("x", (d, i) -> x({x: .9 * ~~(i / m) / n}))
              .attr("width", x({x: .9 / n}))
              .each("end", transitionEnd)

      transitionStack = ->
        transitionEnd = ->
          d3.select(this)
            .transition()
            .duration(500)
            .attr("x", 0)
            .attr("width", x({x: .9}))

        vis.selectAll("g.layer rect")
            .transition()
            .duration(500)
            .delay((d, i) -> (i % m) * 10)
            .attr("y", y1)
            .attr("height", (d) -> y0(d) - y1(d))
            .each("end", transitionEnd)

      scope.grouped = false
      scope.$watch 'grouped', (newVal, oldVal) ->
        return if newVal == oldVal

        if newVal
          transitionGroup()
        else
          transitionStack()
)

angular.bootstrap document, ["MLDashboard"]