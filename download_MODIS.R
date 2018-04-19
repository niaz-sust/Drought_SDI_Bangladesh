# This program has been developed by: -----------------------------------

# Begum Rushi, Regional Associate, HKH Region -----------------------------

# For any query, please feel free to contact: begumrabeya.rushi@nasa.gov -------------


rm(list = ls())

library(optparse)


#!/usr/bin/env Rscript
option_list = list(
  make_option(c("-i", "--input_folder"), type="character", default="C:/test/MODIS_Input/", 
              help="input folder directory [default= %default]", metavar="character"),
   make_option(c("-r", "--output_folder"), type="character", default="C:/test/MODIS_processed/", 
              help="output folder directory [default= %default]", metavar="character"),
  make_option(c("-s", "--Start_Date"), type="character", default="2017001", 
              help=" starting year[default= %default]", metavar="character"),
  make_option(c("-e", "--End_Date"), type="character", default="2017032", 
              help=" End year[default= %default]", metavar="character"),
  make_option(c("-p", "--PRODUCT_NAME"), type="character", default="MOD13A2", 
              help="MODIS PRODUCT ID [default= %default]", metavar="character"),
  make_option(c("-a", "--area_extent"), type="character", default="Bangladesh", 
              help="Country Name [default= %default]", metavar="character")
  
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)


if (is.null(opt$input_folder)){
  print_help(opt_parser)
  stop("All arguments must be supplied (input folder directory).n", call.=FALSE)
}

if (is.null(opt$output_folder)){
  print_help(opt_parser)
  stop("All arguments must be supplied (output folder directory).n", call.=FALSE)
}


if(!file.exists(opt$input_folder))dir.create(opt$input_folder,recursive = TRUE)

if(!file.exists(opt$output_folder))dir.create(opt$output_folder,recursive = TRUE)


library(rts)

library(raster)

library(RCurl)



library(MODIS)

library(gdalUtils)


library(rgdal)




lap = opt$input_folder # 'localArcPath'
odp = opt$output_folder # 'outDirPath'

lpdaacLogin(server = "LPDAAC")

MODISoptions(localArcPath = lap, outDirPath = odp)


Sys.setenv(MRT_DATA_DIR  = "C:\\Program Files\\MRT\\data",
           MRT_HOME = "C:\\Program Files\\MRT\\bin",
           PATH="C:\\Program Files\\GDAL")

MODISoptions()

#devtools::install_github('babaknaimi/rts')  # must install the latest one


#setNASAauth("rrushi", "dhaka1219", update = T) # authenticates at NASA's server



runGdal(opt$PRODUCT_NAME, collection = getCollection(opt$PRODUCT_NAME, forceCheck = TRUE),
        begin = opt$Start_Date, end = opt$End_Date, extent = opt$area_extent,
        job = "temporalComposite",SDSstring = "100000000010")








