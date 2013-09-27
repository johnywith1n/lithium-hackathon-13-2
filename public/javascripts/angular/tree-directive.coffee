angular.module('tree.directive', [])
    .directive 'tree', () ->
        appendSvg = (parent) -> parent.append('svg')

        {      
            scope : {
                chartData:'=',
            },
            compile : (tElem) ->        
                (scope, element, attrs) -> 
                    scope.svgParent = d3.select tElem.get(0)
                    scope.$watch 'chartData', (newValue, oldValue) ->
                        scope.svgParent.empty()
                        if scope.chartData?
                            create newValue, "#chart"
                        return
                    return
        }

create = (jsonSource, div) ->
    # Initialize the display to show a few nodes.
    groupMapping = {}
    duration = 500
    update = (source) ->      
      # Compute the new tree layout.
      nodes = tree.nodes(root).reverse()
      
      # Normalize for fixed-depth.
      nodes.forEach (d) ->
        d.y = d.depth * 180

      
      # Update the nodes…
      node = vis.selectAll("g.node").data(nodes, (d) ->
        d.id or (d.id = ++i)
      )
      
      # Enter any new nodes at the parent's previous position.
      nodeEnter = node.enter().append("svg:g").attr("class", "node").attr("transform", (d) ->
        "translate(" + source.y0 + "," + source.x0 + ")"
      ).on("click", (d) ->
        toggle d
        update d
      )
      nodeEnter.append("svg:circle").attr("r", 1e-6).style "fill", (d) ->
        (if d._children then "lightsteelblue" else "#fff")

      nodeEnter.append("svg:text").attr("x", (d) ->
        (if d.children or d._children then -10 else 10)
      ).attr("dy", ".35em").attr("text-anchor", (d) ->
        (if d.children or d._children then "end" else "start")
      ).text((d) ->
        d.name
      ).style "fill-opacity", 1e-6
      
      # Transition nodes to their new position.
      nodeUpdate = node.transition().duration(duration).attr("transform", (d) -> 
       "translate(" + d.y + "," + d.x + ")"
      )
      nodeUpdate.select("circle").attr("r", 4.5).style "fill", (d) ->
        (if d._children then "lightsteelblue" else "#fff")

      nodeUpdate.select("text").style "fill-opacity", 1
      
      # Transition exiting nodes to the parent's new position.
      nodeExit = node.exit().transition().duration(duration).attr("transform", (d) ->
        "translate(" + source.y + "," + source.x + ")"
      ).remove()
      nodeExit.select("circle").attr "r", 1e-6
      nodeExit.select("text").style "fill-opacity", 1e-6
      
      # Update the links…
      link = vis.selectAll("path.link").data(tree.links(nodes), (d) ->
        d.target.id
      )
      
      # Enter any new links at the parent's previous position.
      link.enter().insert("svg:path", "g").attr("class", "link").attr("d", (d) ->
        o =
          x: source.x0
          y: source.y0

        diagonal
          source: o
          target: o

      ).transition().duration(duration).attr "d", diagonal
      
      # Transition links to their new position.
      link.transition().duration(duration).attr "d", diagonal
      
      # Transition exiting nodes to the parent's new position.
      link.exit().transition().duration(duration).attr("d", (d) ->
        o =
          x: source.x
          y: source.y

        diagonal
          source: o
          target: o

      ).remove()
      
      # Stash the old positions for transition.
      nodes.forEach (d) ->
        d.x0 = d.x
        d.y0 = d.y

    # Toggle children.
    toggle = (d) ->
      if d.children
        d._children = d.children
        d.children = null
      else
        d.children = d._children
        d._children = null
    m = [20, 120, 20, 120]
    w = 1600 - m[1] - m[3]
    h = 900 - m[0] - m[2]
    i = 0
    root = undefined
    tree = d3.layout.tree().size([h, w])
    diagonal = d3.svg.diagonal().projection((d) ->
      [d.y, d.x]
    )
    vis = d3.select(div).append("svg:svg").attr("width", w + m[1] + m[3]).attr("height", h + m[0] + m[2]).append("svg:g").attr("transform", "translate(" + m[3] + "," + m[0] + ")")
    svg = d3.select("#chart").select "svg"

    getDatumForBoard = (board) ->
      datum = d3.select(groupMapping[board]).select('circle').datum()
      return {
        x : m[3] + datum.y0
        y : m[0] + datum.x0
      }

    drawLines = () ->
      d3.json "events_jeffsp.json", (events) ->
        colors = ["blue", "red"]
        events = events.filter (d) ->
          d.board_title != "" and groupMapping.hasOwnProperty d.board_title
        points = []
        for event in events
          points.push getDatumForBoard event.board_title
        linePoints = []
        linePoints.push points[0]
        linePoints.push points[1]
        lineFunction = d3.svg.line().x((d) -> return d.x).y((d) -> return d.y).interpolate("linear")
        i = 1
        currentCircle = d3.select(groupMapping[events[1].board_title]).select('circle')
        currentCircle.style("fill", "red")
        curve = svg.append("path").attr("d", lineFunction(linePoints)).attr("stroke", colors[i%2])
                            .attr("stroke-width", 5)
                           .attr("fill", "none")
        i = 2
        linePoints.shift()
        linePoints.push points[2]
        previousCircle = currentCircle
        currentCircle = d3.select(groupMapping[events[2].board_title]).select('circle')
        transition = curve.transition().duration(1250).attr("d", lineFunction(linePoints)).attr("stroke", colors[i%2])
                              .attr("stroke-width", 5)
                             .attr("fill", "none")
        if events[2].board_title isnt events[1].board_title
          transition = transition.transition().duration(0).each () -> previousCircle.transition().style("fill", "#ffffff")
          transition = transition.transition().duration(0).each () -> currentCircle.transition().style("fill", "red")
  
        i = 3
        total = points.length
        while i < total
          console.log i
          linePoints.shift()
          linePoints.push points[i]
          previousCircle = currentCircle
          currentCircle = d3.select(groupMapping[events[i].board_title]).select('circle')
          if events[i].board_title isnt events[i-1].board_title
            transition = transition.transition().duration(0).each () -> previousCircle.transition().style("fill", "#ffffff")
            transition = transition.transition().duration(0).each () -> currentCircle.transition().style("fill", "red")
          transition = transition.transition().duration(1250).attr("d", lineFunction(linePoints)).attr("stroke", colors[i%2]).attr("stroke-width", 5).attr("fill", "black")
          i += 1



    d3.json jsonSource, (json) ->
      toggleAll = (d) ->
        if d.children
          d.children.forEach toggleAll
          toggle d
      root = json
      root.x0 = h / 2
      root.y0 = 0
      
      update root
      d3.selectAll(vis[0][0].childNodes).filter('g').each (d) ->
        groupMapping[d.name] = this
      setTimeout((() -> drawLines()), duration+ 500)
      return



    
