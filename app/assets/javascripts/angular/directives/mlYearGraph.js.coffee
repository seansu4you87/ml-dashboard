MLDashboard.directive('mlYearGraph', ->
  margin = 20
  barWidth = 20
  width = barWidth * 60
  height = 500 - 0.5 - margin
  color = d3.interpolateRgb("#f77", "#77f")

  yMin = 0
  yMax = 30000
  yInterval = 5000

  restrict: 'E'
  terminal: true
  scope:
    val: "="
    grouped: "="
  link: (scope, element, attrs) ->
    n = scope.val.length
    m = scope.val[0].length
    data = d3.layout.stack()(scope.val)
    y = d3.scale.linear()
          .domain([0, yMax])
          .range([0, height])

    # Creating Placeholder Data

    i = 0
    placeholderData = []
    for productArray in scope.val
      groupPlaceholderData = []
      j = 0
      for bucket in productArray
        groupPlaceholderData.push { product: i, index: j }
        j++
      placeholderData.push groupPlaceholderData
      i++

    # Making Graphs and Stuffs

    chart = d3.select(element[0])
              .append("svg")
                .attr("width", width)
                .attr("height", height + margin + 150)


    # x-axis

    currentDivider = 0
    dividerCount = yMax / yInterval
    while currentDivider < dividerCount
      axisHeight = height - (currentDivider * height / dividerCount)
      chart.append("line")
        .attr("x1", 0)
        .attr("x2", width)
        .attr("y1", axisHeight)
        .attr("y2", axisHeight)
        .style("stroke", "#aaa")

      currentDivider++

    # trying to put units next to lines
    # chart
    #   .append("text")
    #   .attr("x", 0)
    #   .attr("y", 450)
    #   .attr("dx", 10)
    #   .attr("dy", ".71em")
    #   .attr("text-anchor", "middle")
    #   .attr("class", "label")
    #   .text("hello")

    # dates for x-axis

    chart.selectAll("text.label")
      .data(data[0])
      .enter().append("text")
        .on("mouseover", hover)
        .on("mouseout", noHover)
        .attr("class", "label")
        .attr("x", (d, i) -> i * barWidth)
        .attr("y", height + 6)
        .attr("dx", barWidth / 2)
        .attr("dy", ".71em")
        .attr("text-anchor", "middle")
        .text((d, i) -> 
          return if d.x % 4 != 0
          "#{d.startDate.getMonth() + 1}/#{d.startDate.getDate()}")

    # holders for the bars
    groups = chart.selectAll("g.layer")
                .data(placeholderData)
                .enter().append("g")
                  .attr("class", "layer")
                  .attr("id", (d, i) -> data[i][0].product)
                  .style("fill", (d, i) -> color(i / (n - 1)))

    bars = groups.selectAll("rect")
              .data((d) -> d)
              .enter().append("rect")
              .attr("x", (d, i) -> i * barWidth)
              .attr("y", height)
              .attr("width", barWidth * 0.95)
              .attr("height", 0)

    # y-axis
    chart.append("line")
      .attr("x1", 0)
      .attr("x2", 0)
      .attr("y1", 0)
      .attr("y2", height)
      .style("stroke", "#000")

    chart.selectAll("text.key")
      .data(data)
      .enter().append("text")
        .attr("class", "key")
        .attr("x", (d, i) -> 155 * Math.floor(i/2) + 15)
        .attr("y", (d, i) -> height  + 42 + 30 * (i%2))
        .attr("dx", barWidth)
        .attr("dy", ".71em")
        .attr("text-anchor", "left")
        .text((d, i) -> d[0].product)

    chart.selectAll("rect.swatch")
      .data(data)
      .enter().append("rect")
        .attr("class", "swatch")
        .attr("y", (d, i) -> height + 36 + 30 * (i%2))
        .attr("x", (d, i) -> 155 * Math.floor(i/2))
        .attr("width", 20)
        .attr("height", 20)
        .style("fill", (d, i) -> color(i / (n - 1)))

    # Popover Stuffs

    popover = d3.select(element[0])
                .append("div")
                .attr("class", "popover fade right in")
                .attr("id", "bar-popover")
                .style("visibility", "hidden")
                .style("top", "400px")
                .style("left", "200px")
                .style("display", "block")
    
    popover.append("div")
              .attr("class", "arrow")

    popover.append("h3")
            .attr("class", "popover-title")
            .text("tip me")

    popover.append("div")
            .attr("class", "popover-content popover-time-range")
            .text("tip me")

    popover.append("div")
            .attr("class", "popover-content popover-units-sold")
            .text("tip me")

    popover.append("div")
            .attr("class", "popover-content popover-revenue")
            .text("tip me")

    # Helper Functions

    bucket = (d, i) -> 
      return null if data[d.product] == undefined
      data[d.product][d.index]

    barHeight = (d, i) -> 
      b = bucket(d, i)
      return 0 unless b
      y(b.y)

    yGrouped = (d, i) ->
      yStart = 0
      for index in [0...d.product] by 1
        yStart += data[index][d.index].y if data[index]
      
      b = bucket(d, i)
      return 0 if b == null
      height - y(bucket(d, i).y + yStart)

    hover = (d, i) ->
      b = bucket(d, i)
      return unless b
      hour = b.hours[0]

      tip = d3.select("#bar-popover")
              .style("top", (event.pageY - 80) + "px")
              .style("left", (event.pageX) + "px")

      setTimeout(=>
        tip.style("visibility", "visible")
      , 250)

      niceDate = (date) -> "#{date.getMonth() + 1}/#{date.getDate()}"

      tip.select(".popover-title").text("#{hour.platform} $#{hour.price}")
      tip.select(".popover-time-range").text("#{niceDate(b.startDate)} - #{niceDate(b.endDate)}")
      tip.select(".popover-units-sold").text("#{b.y} units sold")
      tip.select(".popover-revenue").text("$#{hour.price * b.y} revenue")

    noHover = -> 
      setTimeout(=>
        d3.select("#bar-popover").style("visibility", "hidden")
      , 250)

    scope.$watch 'val', (newVal, oldVal) ->
      return unless newVal

      data = newVal

      groups = chart.selectAll("g.layer")

      if scope.grouped
        bars = groups.selectAll("rect")
                .transition()
                .duration(500)
                .attr("y", (d, i) -> height - barHeight(d, i))
                .attr("height", barHeight)
      else
        bars = groups.selectAll("rect")
                .transition()
                .duration(500)
                .attr("y", yGrouped)
                .attr("height", barHeight)

      groups.selectAll("rect")
            .on("mouseover", hover)
            .on("mouseout", noHover)

    scope.$watch 'grouped', (newVal, oldVal) ->
      return if newVal == oldVal

      if newVal
        end = ->
          d3.select(this)
            .transition()
              .duration(500)
              .attr("y", (d, i) -> height - barHeight(d, i))

        chart.selectAll("g.layer").selectAll("rect")
          .transition()
            .duration(500)
            .delay((d, i) -> (i % m) * 10)
            .attr("x", (d, i) -> i * barWidth + d.product * barWidth / n)
            .attr("width", barWidth * 0.95 / n)
            .each("end", end)
      else
        end = ->
          d3.select(this)
            .transition()
              .duration(500)
              .attr("x", (d) -> d.index * barWidth)
              .attr("width", barWidth * 0.95)

        chart.selectAll("g.layer").selectAll("rect")
          .transition()
            .duration(500)
            .delay((d, i) -> (i % m) * 10)
            .attr("y", yGrouped)
            .each("end", end)


)