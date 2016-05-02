# Makefile for building a model of San Francisco for 3D printing
# This workflow builds a 3D model of San Francisco's topography from a
# digital elevation model of the Bay Area.

# The final output of this workflow is a GCode file that can be used as
# the input to a 3D printer.
.DEFAULT: topography.gcode 

# Convenience target for pre-downloading the source data.
.PHONY: download
download: bay.zip boundaries.zip

# =======================
# Digital Elevation Model
# =======================

# From http://www.ngdc.noaa.gov/dem/squareCellGrid/download/741
bay.zip:
	# Digital Elevation Model (DEM) of the entire Bay Area from NOAA
	wget http://www.ngdc.noaa.gov/dem/squareCellGrid/getArchive/741?gridFormat=ESRI+Arc+ASCII \
		--no-use-server-timestamps \
		--output-document=$@
	
bay.tiff: bay.zip
	unzip -j -u $< "San_Francisco_Bay_DEM_3362/san_francisco_bay_ca_navd88v2.asc"
	gdalwarp -t_srs EPSG:4326 san_francisco_bay_ca_navd88v2.asc $@

# ===============
# City boundaries
# ===============

boundaries.zip:
	# Zipped shapefile containing boundaries of all cities in California
	wget http://www.dot.ca.gov/hq/tsip/gis/datalibrary/zip/Boundaries/Cities2015.zip \
		--no-use-server-timestamps \
		--output-document=$@

boundary.shp: boundaries.zip
	unzip -j -u $<
	# There are two layers with NAME = San Francisco - one for the land part of the city,
	# and one for the ocean part. We only want the land part of the city.
	ogr2ogr -where "NAME = 'San Francisco' AND Notes IS NULL" -t_srs EPSG:4326 $@ Cities2015.shp

# ======================
# 3D topographical model
# ======================

# Check that this TIFF file looks good by loading it as a raster layer in QGIS.
topography.tiff: boundary.shp bay.tiff
	# Cropping to the extent of the city (crop_to_cutline) and downsampling the
	# resulting TIFF (tr xresolution yresolution). Smaller x- and y-resolution
	# values (closer to 0) result in a more detailed map.
	gdalwarp -q -cutline $< -crop_to_cutline -dstalpha -tr 0.0005 0.0005 bay.tiff $@

# Used to transform TIFF -> STL.
phstl/phstl.py:
	git clone https://github.com/anoved/phstl

# Check that this STL file looks good by loading it in Cura using 
# 'Load model file'.
# The x and y dimensions of the STL file are specified in mm.
topography.stl: topography.tiff phstl/phstl.py
	python phstl/phstl.py -x 78.8 -y 51.5 -z 0.00005 $< $@

# TODO(justinmanley): Automate this step.
topography-solid.stl: topography.stl
	echo "In order to print your model, it needs to be transformed from a"
	echo "2-dimensional surface into a solid. You can do that using Blender."
	echo "Follow the instructions at "
	echo "https://github.com/anoved/phstl/blob/master/demo/blender.md"

# TODO(justinmanley): Automate this step.
topography.gcode: topography-solid.stl
	echo "The last step is to generate gcode, which a format that can be read"
	echo "by 3D printers. You can generate gcode using Cura "
	echo "(File > Load model file and File > Save GCode)."
	echo "Make sure you're using a profile that is calibrated for your "
	echo "3D printer."

