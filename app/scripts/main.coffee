window.Visa = do ->

  height = ($ window).height()
  width = ($ window).width()
  landLayer = null
  mapLayers = null
  selected = false
  highlighted = false
  # nodesLayer = null

  _init = ->
    queue()
      .defer d3.json, 'data/map.json'
      .defer d3.json, 'data/countrycodes.json'
      .await _initMap

  _initMap = (error, mapData, countryCodeData, refugeeData, populationData, storiesData) ->
    projection = d3.geo.mercator().scale(height / 4).translate([
      width / 2
      height / 1.6
    ])
    path = d3.geo.path().projection(projection)

    # IE doesn't support co-ordinates

    # Opera doesn't support url cursors and doesn't fall back well...
    zoom = d3.behavior.zoom().translate([
      0
      0
    ]).scale(1).scaleExtent([
      1
      100
    ])

    d3.select("#map").attr("width", width).attr "height", height
    svg = d3.select("#map svg").call(zoom)
    mapLayers = svg.append("g").attr("id", "mapLayers")
    waterLayer = mapLayers.append("rect").attr("id", "water").attr("width", width).attr("height", height)
    mapcountries = topojson.feature(mapData, mapData.objects.countries)
    landLayer = mapLayers.append("g").attr("id", "landLayer")

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

    return

    updateCountryCentroids()

    countryCodes = d3.nest().key((d) -> d.name )
      .rollup((leaves) -> leaves[0].name)
      .map countryCodeData, d3.map

    codeCountries = d3.nest().key((d) -> d.code)
      .rollup((leaves) -> leaves[0].name)
      .map(countryCodeData, d3.map)


  _mapMousedOver = (country) ->
    return false  if highlighted is country
    landLayer.select("#" + country.id).classed "highlighted", highlighted = country
    #_updateNodeStrokes()
    # unless selected
    #   updateLinks()
    #   updateStats()
    #   updateStoryHead()
    $("#" + country.id + ".node").tooltip "show"
    # updateMapTooltipColor()
    return

  _mapMousedOut = (country) ->
    landLayer.select('#' + country.id).classed('highlighted', highlighted = false)

  updateCountryCentroids = ->
    countryCentroids = d3.map()
    landLayer.selectAll("path").each (d) ->
      if d.id is "ZAF"
        countryCentroids.set d.id, path.centroid(d)
      else
        if d.geometry is `undefined`
          console.log d
        else
          countryCentroids.set d.id, path.centroid(getMaxFeature(d))
      return
    return

  _updateNodeStrokes = ->
    if highlighted or selected
      if highlighted and selected
        nodesLayer.selectAll(".node.visible:not(#" + highlighted.id + "):not(#" + selected.id + ")").classed "enabled", false
        nodesLayer.select("#" + highlighted.id).classed "enabled", true  if d3.select("#" + highlighted.id).classed("enabled")
        nodesLayer.select("#" + selected.id).classed "enabled", true  if d3.select("#" + selected.id).classed("enabled")
      else if highlighted
        nodesLayer.selectAll(".node.visible:not(#" + highlighted.id + ")").classed "enabled", false
        nodesLayer.select("#" + highlighted.id).classed "enabled", true  if d3.select("#" + highlighted.id).classed("enabled")
      else if selected
        nodesLayer.selectAll(".node.visible:not(#" + selected.id + ")").classed "enabled", false
        nodesLayer.select("#" + selected.id).classed "enabled", true  if d3.select("#" + selected.id).classed("enabled")
    else
      nodesLayer.selectAll(".node.visible").classed "enabled", true
    return

  init: ->
    _init()

$(Visa.init);
