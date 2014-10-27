window.Visa = do ->

  height = ($ window).height()
  width = ($ window).width()
  landLayer = null
  mapLayers = null
  selected = false
  highlighted = false

  countryCentroids = null
  countryCodes = null
  visa = null
  svg = null

  projection = null
  path = null
  nodesLayer = null
  linksLayer = null
  centroidsData = []

  nodeDataByCode = []
  arc = d3.geo.greatArc().precision(3);


  _init = ->
    queue()
      .defer d3.json, 'data/map.json'
      .defer d3.json, 'data/countrycodes.json'
      .defer d3.csv, 'data/nodes.csv'
      .defer d3.csv, 'data/visa-usa.csv'
      .await _initMap

  _initMap = (error, mapData, countryCodeData, centroidsDatas, visaData) ->
    projection = d3.geo.mercator()
      .scale(height/4).translate([
        width / 2
        height / 1.6
      ])

    path = d3.geo.path().pointRadius(2).projection(projection)

    # IE doesn't support co-ordinates

    # Opera doesn't support url cursors and doesn't fall back well...
    zoom = d3.behavior.zoom().translate([
      0
      0
    ]).scale(1).scaleExtent([
      1
      100
    ])

    # d3.select("#map").attr("width", width).attr "height", height
    svg = d3.select("#map svg").attr("preserveAspectRatio", "xMidYMid").call(zoom)
    mapLayers = svg.append("g").attr("id", "mapLayers")
    waterLayer = mapLayers.append("rect").attr("id", "water").attr("width", width).attr("height", height)
    mapcountries = topojson.feature(mapData, mapData.objects.countries)
    landLayer = mapLayers.append("g").attr("id", "landLayer")
    centroidsData = centroidsDatas

    landLayer.selectAll('.land')
      .data(mapcountries.features)
      .enter()
      .append('path')
      .attr('id', (d) ->
          return d.id;
      )
      .attr('class', 'land visible')
      .attr('d', path)
      .on('mouseover', _mapMousedOver)
      .on('mouseout', _mapMousedOut)
      #.on('click', mapClicked)
      # .on('touchstart', () ->
      #     mapClicked();
      #     d3.event.preventDefault();
      # )


    nodesLayer = mapLayers.append('g').attr('id', 'nodesLayers')


    linksLayer = mapLayers.append('g').attr('id', 'linksLayer');




    countryCodes = d3.nest().key((d) -> d.name )
      .rollup((leaves) -> leaves[0].code)
      .map countryCodeData, d3.map

    codeCountries = d3.nest().key((d) -> d.code)
      .rollup((leaves) -> leaves[0].name)
      .map(countryCodeData, d3.map)


    visa = d3.nest()
      .key (d) -> countryCodes.get(d.country)
      .map visaData, d3.map

    _updateNodeStrokes(visa)

    centroidsDatas.forEach (node, index) ->
      node.coords = nodeCoords(node)
      node.projection = (if node.coords then projection(node.coords) else `undefined`)
      centroidsDatas[index] = node
      return


    nodesLayer.selectAll("circle").data(centroidsDatas.filter((node) ->
        (if node.projection then true else false)
      )).enter().append("circle")
      .attr("cx", (d) -> d.projection[0])
      .attr("cy", (d) -> d.projection[1])
      .attr("r", 1)
      .attr('strokeWidth', '0.5px')
      .attr("stroke", 'red')
      .attr "opacity", 0.5

    centroids = d3.nest().key((d) -> d.code)
      .rollup((leaves) -> leaves[0])
      .map(centroidsDatas, d3.map)

    console.log centroids
    linksLayer
      .append 'path'
      .attr "class", "node"
      .attr "fill", "none"
      .attr 'd', (d) ->
        path(arc(
          source: centroids.get('AUS').coords
          target: centroids.get('USA').coords
        ))



  nodeCoords = (node) ->
    lon = parseFloat(node.lon)
    lat = parseFloat(node.lat)
    return null  if isNaN(lon) or isNaN(lat)
    [
      lon
      lat
    ]

  _mapMousedOver = (country) ->
    return false  if highlighted is country
    landLayer.select("#" + country.id).classed "highlighted", highlighted = country
    $("#" + country.id + ".node").tooltip "show"
    return

  _mapMousedOut = (country) ->
    landLayer.select('#' + country.id).classed('highlighted', highlighted = false)



  _updateNodeStrokes = (visa) ->


      return


  init: ->
    _init()

$(Visa.init);
