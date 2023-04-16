clean_typos<- function(df_name){
  
  df <- get(df_name)
  #df_name <- deparse(substitute(df))
  
  df$club_involved_name <- ifelse(df$club_involved_name == "Stade Rennais", "Rennes", df$club_involved_name)
  
 # df$club_involved_name <- ifelse(df$club_involved_name == "Bay. Leverkusen", "B. Leverkusen", df$club_involved_name)
  
  df$club_involved_name <- ifelse(df$club_involved_name == "FC Bayern", "Bayern Munich", df$club_involved_name)
  
  df$club_name <- ifelse(df$club_name == "Moreirense ", "Moreirense", df$club_name)
  
  if (df_name == "d1993_1994" | df_name == "d1994_1995"){
    df$club_involved_name <- ifelse(df$club_name == "Willem II" & df$club_involved_name == "Unknown", 
                                    "Netherlands", 
                                    df$club_involved_name)
  } else if (df_name == "d2014_2015"){ 
    df$club_involved_name <- ifelse(df$club_name == "Barcelona" & df$club_involved_name == "Uk", 
                                      "Liverpool FC", 
                                      df$club_involved_name)  
    
    
  } else if (df_name == "d2015_2016"){ 
    df$club_involved_name <- ifelse(df$club_name == "Man City" & df$player_name == "Raheem Sterling", 
                                    "Liverpool FC", 
                                    df$club_involved_name)  
  }
  
  else if (df_name == "d2017_2018"){ 
    df$club_involved_name <- ifelse(df$club_name == "Barcelona" & df$player_name == "Philippe Coutinho", 
                                    "Liverpool FC", 
                                    df$club_involved_name)  
  }
  df$fee_cleaned <- gsub(",", ".", df$fee_cleaned)
  df$fee_cleaned<- as.numeric(df$fee_cleaned)
  
  assign(df_name, df, envir = .GlobalEnv)
  #return(df)
}






fineTuning<- function(df){
  # Some finetuning operation:
  
  # 1 delete the few club that doesn't match (are very few and most of theme are teams in the lowest leagues in Europ)
  allowed_club <- c("Est_EU","Belgium","North_EU","Central_EU","free agents", "Italy", "South America", "Turkey", "Spain", "France", "Uk", "Russia", "Portugal","Germany","Asia","North America", "Netherlands", "Africa")
  df_selezionato <- df[, c( "club_name","club_involved_name", "fee_cleaned","league_name")]
  
  new_clubs <- setdiff(df_selezionato$club_involved_name,df_selezionato$club_name)
  to_delete <- setdiff(new_clubs,allowed_club)
  df_selezionato <- subset(df_selezionato, !df_selezionato$club_involved_name %in% to_delete)
  
  # 2 Assign each Node to their League
  club_name_match <- unique(df_selezionato$club_name)
  df_match <- data.frame(club_name = club_name_match, league_name = NA)
  df_match$league_name <- df_selezionato$league_name[match(df_match$club_name, df_selezionato$club_name)]
  
  # 3 For the others nodes in allowes_club, we use the following function for assign the correct type
  
  for (club in allowed_club) {
    if (club == "Spain"){
      attr = "Primera Division"
      
    }else if (club == "Italy"){
      attr = "Serie A"
      
    }else if (club == "France"){
      attr = "Ligue 1"
      
    }else if (club == "Portugal"){
      attr = "Liga Nos"
      
    }else if (club == "Uk"){
      attr = "Premier League"
      
    }else if (club == "Germany"){
      attr = "1 Bundesliga"
      
    }else if (club == "Netherlands"){
      attr = "Eredivisie"
    }else{
      attr= "Other"
    }
    
    new_row <- c(club, attr)
    df_match <- rbind(df_match, new_row)
  }
  #if (df == d1993_1994| df == d1994_1995){
  #  new_row <- c("Willem II", "Eredivisie")
  #  df_match <- rbind(df_match, new_row)
 # }
  combined_cols <- paste(df_selezionato$club_name,df_selezionato$club_involved_name, sep = "_")
  df_selezionato$combined <- combined_cols
  result <- table(df_selezionato$combined)
  result_df <- data.frame(combined = names(result), count = as.numeric(result))
  
  
  df_selezionato <- aggregate(fee_cleaned ~  club_name + club_involved_name  , data = df_selezionato, FUN = mean, na.rm = TRUE)
  combined_cols <- paste(df_selezionato$club_name,df_selezionato$club_involved_name, sep = "_")
  df_selezionato$combined <- combined_cols
  
  df_selezionato <- merge(df_selezionato, result_df, by = "combined")
  df_selezionato <- subset( df_selezionato, select = -combined )
  
  
  
  return(list(df_match=df_match, df_selezionato=df_selezionato))
  
}


get_modularity <- function(df_match,df_selezionato, archi){
  
  remove_for_com_detect <- c("Est_EU","Belgium","North_EU","Central_EU","free agents", "South America", "Turkey", "Russia", "Asia","North America", "Africa")
  
  # Remove them from 'archi' creating a df
  archi_Community_detect <-subset(archi, !(df_selezionato$From %in% remove_for_com_detect | df_selezionato$To %in% remove_for_com_detect))
  
  # Remove them from df_match
  df_match_Community_detect<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))
  
  
  # Assign two weights : 1) for how many times each row is repeted 2) the sum of money for every time the rows is repeted
  
  # Create the New Graph
  g_cd<-graph_from_edgelist(archi_Community_detect, directed = F)
  
  
  # Assign the right league
  V(g_cd)$club_name <- V(g_cd)$name
  V(g_cd)$type <- df_match_Community_detect$league_name[match(V(g_cd)$club_name, df_match_Community_detect$club_name)]
  
  # Simplify
  g_cd <- simplify(g_cd)
  
  value <- modularity(g_cd, as.numeric(as.factor(V(g_cd)$type)))
  return(value)
}












classify_edge_width <- function(fee) {
  if (fee >= 0 && fee <= 1) {
    return(1)
  } else if (fee > 1 && fee <= 20) {
    return(2)
  }
  else if (fee > 20 && fee <= 50) {
    return(3)
  }
  else if (fee > 50 && fee <= 99) {
    return(4.5)
  }
  
  else  {
    return(7)
  }
}

classify_edge_color <- function(fee) {
  if (fee >= 0 && fee <= 1) {
    return("#838B8B")
  } else if (fee > 1 && fee <= 20) {
    return("black")
  }
  else if (fee > 20 && fee <= 50) {
    return("cyan3")
  }
  else if (fee > 50 && fee <= 99)  {
    return("orange")
  }
  else  {
    return("#CD2626")
  }
}

get.backbone = function(graph, alpha = 0.0005, directed = FALSE)
{
  G = graph
  
  # get edgelist
  edgelist = get.data.frame(G)
  colnames(edgelist) = c("from","to","weight")
  
  # get nodes list
  nodes = unique(c(edgelist[,1], edgelist[,2]))
  N = length(nodes)
  
  # initialize backbone dataframe
  backbone = NULL
  
  cat("Disparity Filter\n")
  cat("alpha =", alpha, "\n")
  cat("\nOriginal graph\n")
  print(G)
  
  for (i in 1:N) # for each node
  {
    # get neighbors
    nei = edgelist[edgelist$from == nodes[i],]
    nei = rbind(nei, edgelist[edgelist$to == nodes[i],])
    
    # get degree for node i
    k_i = length(edgelist$to[edgelist$to == nodes[i]]) + length(edgelist$to[edgelist$from == nodes[i]])
    
    if (k_i>1)
    {
      for (j in 1:k_i) # for each neighbor
      {
        # compute weighted edge
        p_ij = as.numeric(nei$weight[j]) / sum(as.numeric(nei$weight))
        
        # VIA INTEGRATION
        #integrand_i = function(x){(1-x)^(k_i-2)}
        #integration = integrate(integrand_i, lower = 0, upper = p_ij)
        #alpha_ij = 1 - (k_i - 1) * integration$value
        
        alpha_ij = (1 - p_ij)^(k_i - 1)
        
        if (alpha_ij < alpha)
        {
          backbone = rbind(backbone, c(nei$from[j], nei$to[j], nei$weight[j]))
        }
      }
    }
  }
  
  colnames(backbone) = c("from","to","weight")
  backbone = unique(backbone[,c('from','to','weight')])
  G_backbone = graph.data.frame(backbone, directed = directed)
  
  cat("\nBackbone graph\n")
  print(G_backbone)
  return(G_backbone)
}





