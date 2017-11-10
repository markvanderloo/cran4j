
deplinks <- function(df, type=c("depends","imports","linkingto","enhances")){
  # list of vector of dependency names
  deps <- strsplit(df[[type]],", ")
  # remove dependency on certain R versions
  deps <- lapply(deps, function(x) x[!grepl("^R ?\\(",x)])
  
  L <- lapply(seq_along(deps),function(i){
    if (is.na(deps[[i]]) || length(deps[[i]])==0 ){
      return(data.frame(start=integer(0),end=integer(0)))
    }
    start <- df[i,1]
    end <- df[match(deps[[i]],df[["package"]]),1]
    data.frame(start=start,end=end)
  })

  dps <- do.call('rbind',L)
  
  dps <- data.frame(start=dps$start, type=tolower(type),end=dps$end)  
}


revert <- function(deps,newname){
  nm <- names(deps)
  deps <- setNames(deps[3:1],nm)
  deps[,2] <- newname
  deps
}

