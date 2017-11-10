# setup files for neo4j

# todo: recommended pkgs staan niet
# onder available.packages.
source('func.R')


library(hashr)
library(dplyr)

### Obtain raw data ----

# CRAN packages
a <- tools::CRAN_package_db()

# list of R-recommended packages
recommended <- c("base"
  ,"compiler"
  ,"datasets"
  ,"graphics"
  ,"grDevices"
  ,"grid"
  ,"methods"
  ,"parallel"
  ,"splines"
  ,"stats"
  ,"stats4"
  ,"tcltk"
  ,"tools"
  ,"translations"
  ,"utils")

L <- lapply(recommended, function(x){
  as.data.frame(lapply(packageDescription(x),identity),stringsAsFactors=FALSE)
})

b <- dplyr::bind_rows(L)
a <- dplyr::bind_rows(a,b)
names(a) <- tolower(names(a))


## Package nodes ----
pkgnodes <- a[c(
  "package"
  , "version"
  , "date"
  , "priority"
  , "title"
  , "description"
)
]
rownames(pkgnodes) <- NULL
id <- abs(hash(do.call(paste,pkgnodes)))
pkgnodes <- cbind(data.frame(id=id), pkgnodes, stringsAsFactors=FALSE)
names(pkgnodes)[1] <- "package:ID(Package)"
write.csv(pkgnodes,"neo4j/packages.csv", na="", row.names=FALSE)

# add ID column to original data
a <- cbind(id = pkgnodes[,1],a)


## Licence nodes ----
licence <- unique(a[c(
  "license"
  ,"license_is_foss"
  ,"license_restricts_use"
)])
id <- abs(hash(do.call(paste,licence)))

licence <- cbind(data.frame(id=id),licence)
row.names(licence) <- NULL
head(licence)

names(licence)[1] <- "licence:ID(Licence)"

write.csv(licence, "neo4j/package.csv", na="", row.names = FALSE)

## edges ----

i <- match(a$license,licence$name)
end <- licence[i,1]

pkg_lc <- data.frame(
    x = pkgnodes[[1]]
  , y = end
  )

names(pkg_lc) <- c(":START_ID(Package)",":END_ID(Licence)")
write.csv(pkg_lc,"neo4j/pkg_licence.csv", row.names=FALSE)


## all links will have a 'enhances'-like character so

dps <- deplinks(a,type="depends")
dps <- revert(dps,newname="is depended on by")


ipt <- deplinks(a,"imports")
ipt <- revert(ipt, "is imported by")

lto <- deplinks(a,"linkingto")
lto <- revert(lto,"is linked from")


# some pkgs enhance software not on CRAN
enh <- deplinks(a,"enhances") %>% filter(!is.na(end))


links <- bind_rows(dps,ipt,lto,enh)
write.csv(links,"neo4j/pkg_links.csv",row.names=FALSE)


