
# This program has been developed by: -----------------------------------

# Begum Rushi, Regional Associate, HKH Region -----------------------------

# For any query, please feel free to contact: begumrabeya.rushi@nasa.gov -------------

rm(list = ls())

library(optparse)


#!/usr/bin/env Rscript
option_list = list(
  make_option(c("-i", "--input_folder"), type="character", default="C:/Training_Materials/Monthly_Composite/", 
              help="input folder directory [default= %default]", metavar="character"),
  make_option(c("-r", "--output_folder"), type="character", default="C:/Training_Materials/Monthly_Composite/Indices/", 
              help="output folder directory [default= %default]", metavar="character"),
  make_option(c("-Y", "--Start_Year"), type="integer", default="2015", 
              help=" starting year[default= %default]", metavar="integer"),
  make_option(c("-N", "--End_Year"), type="integer", default="2017", 
              help=" starting year[default= %default]", metavar="integer")
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
library(raster)
library(MODIS)

library(gdalUtils)

library(rgdal)

library(lubridate)

## extract required layers

product_list<-c("LST","NDVI","PRCP")

indices_list<-c("Final_TCI","Final_VCI","Final_PCI")



# Reading Monthly Composite File ------------------------------------------


for (m in 1:length(product_list)) {
  

  file_name<-list.files(paste0(opt$input_folder),
                     pattern = product_list[m], full.names = TRUE)

  

  monthly.raster<-stack(file_name)
  
  date_begin<-paste(opt$Start_Year,"-1-1",sep = "")
  date_end<-paste(opt$End_Year,"-12-31",sep = "")
  
  date1<- seq(as.Date(date_begin), as.Date(date_end), "months")
  
  
  
  total_month<- month(date1)
  
  max.raster<- stackApply(monthly.raster, total_month, fun = max,na.rm=TRUE)

  
  min.raster<-stackApply(monthly.raster, total_month, fun = min,na.rm=TRUE)
  
  no_rep<-length(total_month)/12
  
  max.brick <- replicate( no_rep, max.raster )
  
  max.raster <- stack( max.brick )
  
  min.brick <- replicate( no_rep, min.raster )
  
  min.raster <- stack( min.brick )
  
  
  assign(paste0(product_list[m],"_monthly"), monthly.raster)
  
  assign(paste0("max",product_list[m]), max.raster)
  assign(paste0("min",product_list[m]), min.raster)
  
}




rm(monthly.raster)
rm(max.raster)

rm(min.raster)



# Calculating TCI ---------------------------------------------------------



numerator_LST<-overlay(maxLST,LST_monthly,fun=function(r1, r2){return(r1-r2)})

denominator_LST<-overlay(maxLST,minLST,fun=function(r1, r2){return(r1-r2)})

TCI<-overlay(numerator_LST,denominator_LST,fun=function(x, y){ x/y})



TCI_output_file<-paste0("TCI.tif")

TCI_path<-paste0(opt$output_folder,TCI_output_file)


writeRaster(TCI, filename=TCI_path,bylayer=F,format="GTiff", overwrite=TRUE)



# Calculating VCI ---------------------------------------------------------

numerator_NDVI<-overlay(NDVI_monthly,minNDVI,fun=function(r1, r2){return(r1-r2)})

denominator_NDVI<-overlay(maxNDVI,minNDVI,fun=function(r1, r2){return(r1-r2)})

VCI<-overlay(numerator_NDVI,denominator_NDVI,fun=function(x, y){ x/y})



VCI_output_file<-paste0("VCI.tif")

VCI_path<-paste0(opt$output_folder,VCI_output_file)


writeRaster(VCI, filename=VCI_path,bylayer=F,format="GTiff", overwrite=TRUE)



# Calculating PCI ---------------------------------------------------------

numerator_PRCP<-overlay(PRCP_monthly,minPRCP,fun=function(r1, r2){return(r1-r2)})

denominator_PRCP<-overlay(maxPRCP,minPRCP,fun=function(r1, r2){return(r1-r2)})

PCI<-overlay(numerator_PRCP,denominator_PRCP,fun=function(x, y){ x/y})



PCI_output_file<-paste0("PCI.tif")

PCI_path<-paste0(opt$output_folder,PCI_output_file)


writeRaster(PCI, filename=PCI_path,bylayer=F,format="GTiff", overwrite=TRUE)



# Calculating SDI ---------------------------------------------------------
r.new<-resample(PCI, TCI, method="bilinear")

crs(r.new)<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 "

PCI<-r.new


Final_SDI<-stack()

for (n in 1:length(total_month)) {
  
  index.stack<-stack(TCI[[n]],VCI[[n]],PCI[[n]])
  
  
  raster.point<-as.data.frame(rasterToPoints(index.stack))
  
  colnames(raster.point)<-c("x","y","TCI","VCI","PCI")
  
  raster.point[is.na(raster.point)] <- 0
  
  
  
  pca.cal <- princomp(~raster.point$TCI+raster.point$VCI+raster.point$PCI, data = raster.point,
                      cor = F, scores = TRUE)
  
  
  
  pca.value<-as.data.frame(pca.cal$scores)
  
  raster.point$PCA1<-pca.value$Comp.1
  
  
  SDI<-data.frame(raster.point$x,raster.point$y,raster.point$PCA1)
  
  colnames(SDI)<-c("x","y","SDI")
  
  coordinates(SDI) <- ~ x + y
  
  gridded(SDI) <- TRUE
  # coerce to raster
  raster.SDI <- raster(SDI)
  
  
  
  crs(raster.SDI)<-"+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 "
  
  Final_SDI<-stack(Final_SDI,raster.SDI)
  
  
}


SDI_output_file<-paste0("SDI.tif")

SDI_path<-paste0(opt$output_folder,SDI_output_file)

writeRaster(Final_SDI, filename=SDI_path,bylayer=F,format="GTiff", overwrite=TRUE)

