MLDashboard.directive('mlYearGraph', ->
  margin = 20
  barWidth = 20
  width = barWidth * 60
  height = 500 - 0.5 - margin
  color = d3.interpolateRgb("#f77", "#77f")

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
          .domain([0, 30000])
          .range([0, height])

    i = 0
    placeholder = []
    for productArray in scope.val
      groupPlaceholder = []
      j = 0
      for bucket in productArray
        groupPlaceholder.push { product: i, index: j }
        j++
      placeholder.push groupPlaceholder
      i++

    chart = d3.select(element[0])
              .append("svg")
                .attr("width", width)
                .attr("height", height + margin + 100)

    groups = chart.selectAll("g.layer")
                .data(placeholder)
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

    chart.selectAll("text.label")
      .data(data[0])
      .enter().append("text")
        .attr("class", "label")
        .attr("x", (d, i) -> i * barWidth)
        .attr("y", height + 6)
        .attr("dx", barWidth / 2)
        .attr("dy", ".71em")
        .attr("text-anchor", "middle")
        .text((d, i) -> 
          return i
          return if d.x % 4 != 0
          "#{d.startDate.getMonth() + 1}/#{d.startDate.getDate()}")
    
    chart.append("line")
      .attr("x1", 0)
      .attr("x2", width)
      .attr("y1", height)
      .attr("y2", height)
      .style("stroke", "#000")

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
        .attr("x", (d, i) -> 155 * Math.floor(i/3) + 15)
        .attr("y", (d, i) -> height  + 42 + 30 * (i%3))
        .attr("dx", barWidth)
        .attr("dy", ".71em")
        .attr("text-anchor", "left")
        .text((d, i) -> d[0].product)

    chart.selectAll("rect.swatch")
      .data(data)
      .enter().append("rect")
        .attr("class", "swatch")
        .attr("y", (d, i) -> height + 36 + 30 * (i%3))
        .attr("x", (d, i) -> 155 * Math.floor(i/3))
        .attr("width", 20)
        .attr("height", 20)
        .style("fill", (d, i) -> color(i / (n - 1)))

    scope.$watch 'val', (newVal, oldVal) ->
      return unless newVal

      data = newVal

      bucket = (d, i) -> data[d.product][d.index]

      barHeight = (d, i) -> y(bucket(d, i).y)

      yGrouped = (d, i) ->
        yStart = 0
        for index in [0...d.product] by 1
          yStart += data[index][d.index].y
        
        height - y(bucket(d, i).y + yStart)

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