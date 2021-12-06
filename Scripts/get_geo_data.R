library(sf)
library(rnaturalearth)
library(dplyr)

# file to save spatial data
gpkg_dir <- "data"
if (!dir.exists(gpkg_dir)) {
    dir.create(gpkg_dir)
}
f_ne <- file.path(gpkg_dir, "gis-data.gpkg")

# political boundaries
# land border with lakes removed
ne_land <- ne_download(scale = 50, category = "cultural",
                       type = "admin_0_countries_lakes",
                       returnclass = "sf") %>%
    filter(CONTINENT == "North America") %>%
    st_set_precision(1e6) %>%
    st_union()
# country lines
# downloaded globally then filtered to north america with st_intersect()
ne_country_lines <- ne_download(scale = 50, category = "cultural",
                                type = "admin_0_boundary_lines_land",
                                returnclass = "sf") %>% 
    st_geometry()
ne_country_lines <- st_intersects(ne_country_lines, ne_land, sparse = FALSE) %>%
    as.logical() %>%
    {ne_country_lines[.]}
# states, north america
ne_state_lines <- ne_download(scale = 50, category = "cultural",
                              type = "admin_1_states_provinces_lines",
                              returnclass = "sf") %>%
    filter(adm0_a3 %in% c("USA", "CAN")) %>%
    mutate(iso_a2 = recode(adm0_a3, USA = "US", CAN = "CAN")) %>% 
    select(country = adm0_name, country_code = iso_a2)

mn <- file.path("data", "tl_2016_27_cousub", "tl_2016_27_cousub.shp") %>% 
    read_sf() %>%
    st_transform(crs = paste("+proj=sinu +lon_0=0 +x_0=0 +y_0=0",
                             "+a=6371007.181 +b=6371007.181 +units=m +no_defs"))

# output
unlink(f_ne)
write_sf(ne_land, f_ne, "ne_land")
write_sf(ne_country_lines, f_ne, "ne_country_lines")
write_sf(ne_state_lines, f_ne, "ne_state_lines")
write_sf(mn, f_ne, "MN")

