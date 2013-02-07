MLDashboard.directive('mlYearGraph', ->
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

    console.log "linking"
    console.log scope.val

    vis = d3.select(element[0])
              .append("svg")
                .attr("width", width)
                .attr("height", height + margin + 100)

    scope.$watch 'val', (newVal, oldVal) ->
      console.log "watching val"

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
          .attr("width", x({x: 0.9}))
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
                    .text((d, i) -> 
                      return if d.x % 4 != 0
                      "#{d.startDate.getMonth() + 1}/#{d.startDate.getDate()}")

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