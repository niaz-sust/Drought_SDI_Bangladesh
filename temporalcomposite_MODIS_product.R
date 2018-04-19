# This program has been developed by: -----------------------------------

# Begum Rushi, Regional Associate, HKH Region -----------------------------

# For any query, please feel free to contact: begumrabeya.rushi@nasa.gov -------------


rm(list = ls())

library(optparse)


#!/usr/bin/env Rscript
option_list = list(
  make_option(c("-i", "--input_folder"), type="character", default="C:/test/MODIS_processed/temporalComposite/", 
              help="input folder directory [default= %default]", metavar="character"),
  make_option(c("-r", "--output_folder"), type="character", default="C:/test/MODIS_Monthly_Composite/", 
              help="output folder directory [default= %default]", metavar="character"),
  make_option(c("-f", "--output_file"), type="character", default="Monthly_NDVI_Composite.tif", 
              help="output file name [default= %default]", metavar="character"),
  make_option(c("-t", "--time_step"), type="character", default="month", 
              help="Time Step [default= %default]", metavar="character")
  
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


if(!file.exists(opt$output_folder))dir.create(opt$output_folder,recursive = TRUE)


library(mapview)

library(MODIS)

library(gdalUtils)

library(rgdal)


library(signal)

library(zoo)

## import 16-day ndvi
ndvi <- list.files(paste0(opt$input_folder),
                   pattern = "NDVI.tif", full.names = TRUE)



## import corresponding composite day of the year
cdoy <- list.files(paste0(opt$input_folder),
                   pattern = "day_of_the_year.tif", full.names = TRUE)

## create monthly mean value composites

monthly_composite<-temporalComposite(ndvi, cdoy, timeInfo = extractDate(cdoy, asDate =
                                                            TRUE)$inputLayerDates, interval = c(opt$time_step),
                        fun = mean, na.rm = TRUE)


output_file<-paste0(opt$output_file)

output_directory<-paste0(opt$output_folder,output_file)

writeRaster(monthly_composite, filename=output_directory,bylayer=F,format="GTiff", overwrite=TRUE)




