# Makefile for building a model of San Francisco for 3D printing

.PHONY: download
download: bay.zip boundaries.zip

# From http://www.ngdc.noaa.gov/dem/squareCellGrid/download/741
bay.zip:
	# Digital Elevation Model (DEM) of the entire Bay Area from NOAA
	wget http://www.ngdc.noaa.gov/dem/squareCellGrid/getArchive/741?gridFormat=ESRI+Arc+ASCII \
		--no-use-server-timestamps \
		--output-document=$@
	
bay.dem: bay.zip
	unzip -j $< "San_Francisco_Bay_DEM_3362/san_francisco_bay_ca_navd88v2.asc"
	touch $@

boundaries.zip:
	# Zipped shapefile containing boundaries of all cities in California
	wget http://www.dot.ca.gov/hq/tsip/gis/datalibrary/zip/Boundaries/Cities2015.zip \
		--no-use-server-timestamps \
		--output-document=$@

boundaries.shp: boundaries.zip
	unzip -j $<
	touch $@

