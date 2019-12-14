

# Making Interactive Maps with R

# REFERENCE: https://rstudio.github.io/leaflet/

# Libraries
# ==============================================================================
library(dplyr)
library(leaflet)
library(htmlwidgets)


# Reading in data
# ==============================================================================
events = read.csv("data/sample/event_short.csv", stringsAsFactors = FALSE)
animals = read.csv("data/sample/animal_short.csv", stringsAsFactors = FALSE)

# Check what we just imported 
# ------------------------------------------------------------------------------
# Check what we have:
head(events)
# What's the structure of our event data?
str(events)


# Similarly, for the `animals` data:
# ------------------------------------------------------------------------------
head(animals)
str(animals)


# *********
# IMPORTANT: YOU MAY NOT NEED THE LINE OF CODE BELOW WITH YOUR DATA.
# RUN str(animals) TO SEE IF YOU HAVE SiteLatitude and SiteLongitude IN YOUR
# ANIMAL DATSET.
# IF YES, YOU DON'T NEED TO JOIN.
# I MADE A SMALL SUBSET FOR THIS TUTORIAL, SO I NEED TO JOIN!! 
animals = dplyr::left_join(animals, events, by = "GAINS4_EventID")
# *********



# Getting unique sites for mapping (to avoid overlapping)
# ------------------------------------------------------------------------------

sites = events %>%
    group_by(SiteName, StateProv, District, SiteLatitude, SiteLongitude) %>%
    summarise(n = n())



# Starting with leaflet 
# ==============================================================================
# The leaflet package enables us to create beautiful interactive maps in R. 
# To begin, let's create an empty map. See what running the following command 
# gives you.

leaflet() %>% addTiles()


# Adding a different base map
# ==============================================================================
# Use a more aesthetic base map, similar to the ones we used in the QGIS session.
# To see  all your options fo extra base maps, go to:
#     http://leaflet-extras.github.io/leaflet-providers/preview/index.html


leaflet() %>% addProviderTiles(providers$Esri.NatGeoWorldMap)


# Map sites
# ==============================================================================
# We do that with the `addCircleMarkers` function.
# If you want to see what arguments it needs, run `?addCircleMarkers` in
# your R console.

map_sites = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude)

map_sites


# Adjust the size of the circles
# ------------------------------------------------------------------------------
# we do this by setting the `radius`

map_sites = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude,
                     radius = 4)

map_sites


# Show popups
# ==============================================================================
# How about we add some popupp information? If you click on a point, a popup will
# display whatever information you set it up to show. 

# we do this by using the `popup` argument
map_sites = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude,
                     radius = 4,
                     popup = ~SiteName)

map_sites


# For the above, we set it so the SiteName would pop up. We can add more
# information.

# run ?paste0 to see what it does
# <br> is html code for going to the next line. Otherwise our popup will be one
# long line, and difficult to read.

# More detailed popups
sites$site_info = paste0("Site name: ", sites$SiteName, "<br>",
                         "No. of events: ", sites$n, "<br>",
                         "StateProv: ", sites$StateProv, "<br>",
                         "District: ", sites$District, "<br>",
                         "Latitude: ", sites$SiteLatitude, "<br>",
                         "Longitude: ", sites$SiteLongitude)


map_site_info = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude,
                     radius = 4,
                     popup = ~site_info)

map_site_info


# Adding a country polygon 
# ==============================================================================
# To help put our site locations into context, we import a polygon layer for our
# country, and display it below the site data. 


ctry_poly = readRDS("data/GIS/country_polygons/USA/gadm36_USA_1_sp.rds")

map_ctry_poly = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addPolygons(data = ctry_poly)

map_ctry_poly


# change the color of the polygon
map_ctry_poly = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addPolygons(data = ctry_poly,
                color = "green")

map_ctry_poly


# ==============================================================================
# Put it all together
# ==============================================================================

map = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap) %>%
    addPolygons(data = ctry_poly,
                color = "green") %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude,
                     weight = 3,
                     radius = 4,
                     opacity = 0.7,
                     popup = ~site_info)

map



# Give options for turning layers on/off
# ==============================================================================
# we do this using the `group` argument
# then, we use another function, `addLayersControl`, which enables us to
# decide which layer groups to show/toggle.

map = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap,
                     group = "NatGeo") %>%
    addPolygons(data = ctry_poly,
                color = "green",
                group = "USA regions") %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude,
                     weight = 3,
                     radius = 4,
                     opacity = 0.7,
                     popup = ~site_info,
                     group = "Sites")


map = map %>%
    addLayersControl(
    overlayGroups = c("USA regions", "Sites"),
    options = layersControlOptions(collapsed = FALSE))

map


# Add the animal sampling data
# ==============================================================================
# We add the animal data and use the `clusterOptions` argument so that
# leaflet aggregates the numbers for us.

# first, let's map animals as is (without sites)
map_animals = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap,
                     group = "NatGeo") %>%
    addPolygons(data = ctry_poly,
                color = "green",
                group = "USA regions") %>%
    addCircleMarkers(data = animals, lng = ~SiteLongitude, lat = ~SiteLatitude,
                     weight = 2,
                     radius = 4,
                     group = "Animal clusters")

map_animals


# now, let's try the aggregation argument `clusterOptions`, which enables us to
# show numbers of animals
map_animals = leaflet() %>% 
    addProviderTiles(providers$Esri.NatGeoWorldMap,
                     group = "NatGeo") %>%
    addPolygons(data = ctry_poly, group = "USA regions") %>%
    addCircleMarkers(data = animals, lng = ~SiteLongitude, lat = ~SiteLatitude,
                     weight = 2,
                     radius = 4,
                     group = "Animal clusters",
                     clusterOptions = markerClusterOptions())
    
map_animals



# Finally, let's add our animal data to the map with event data in it
# ==============================================================================
map = leaflet() %>%
    addProviderTiles(providers$Esri.NatGeoWorldMap,
                     group = "NatGeo") %>%
    addPolygons(data = ctry_poly,
                color = "green",
                group = "USA regions") %>%
    addCircleMarkers(data = sites,
                     lng = ~SiteLongitude,
                     lat = ~SiteLatitude,
                     weight = 3,
                     radius = 4,
                     opacity = 0.7,
                     popup = ~site_info,
                     group = "Sites") %>%
    addCircleMarkers(data = animals, lng = ~SiteLongitude, lat = ~SiteLatitude,
                     weight = 2,
                     radius = 4,
                     group = "Animal clusters",
                     clusterOptions = markerClusterOptions())


map = map %>%
    addLayersControl(
    overlayGroups = c("USA regions", "Sites", "Animal clusters"),
    options = layersControlOptions(collapsed = FALSE))


map


# Now, save your map
# ==============================================================================

# NOTE: YOU CAN EITHER PROVIDE THE FULL FILE LOCATION TO SPECIFY EXACT PLACE
#       TO SAVE IT (results -> maps FOLDER)
#       OR
#       JUST THE FILE NAME, AND IT WILL SAVE TO 2019_predict-conference FOLDER

saveWidget(map, "~/projects/2019_predict-conference/results/maps/map_sites_animal.html")
# OR
saveWidget(map, "map_sites_animal.html")
