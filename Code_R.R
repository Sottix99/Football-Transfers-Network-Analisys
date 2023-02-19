library(readr)
library(dplyr)
library(igraph)
library(ggplot2)
library("ggridges")
source("functions.R")
library(gridExtra)
install.packages("remotes")
remotes::install_github("davidsjoberg/ggstream")
library(ggstream)

##########################################
# 1 Send Raw data to Python for cleaning #
##########################################

# Load the datasets
X1_bundesliga <- read_csv("data/1-bundesliga.csv")
eredivisie <- read_csv("data/eredivisie.csv")
liga_nos <- read_csv("data/liga-nos.csv")
ligue_1 <- read_csv("data/ligue-1.csv")
premier_league <- read_csv("data/premier-league.csv")
primera_division <- read_csv("data/primera-division.csv")
serie_a <- read_csv("data/serie-a.csv")

# Stack the datasets
seriea=serie_a
fra=ligue_1
ger=X1_bundesliga
ing=premier_league
esp=primera_division
por=liga_nos
ola=eredivisie 
Out_For_Cleaning=rbind(seriea, fra, ger, ing, esp, por, ola)

# Export Data
write.csv2(Out_For_Cleaning, file = "Out_For_Cleaning.csv")



##########################################
# 2 Import the cleaned datasets          #
##########################################

# Create a vector containing the name of all datasets
datasets <- paste0(1992:2021, "_", 1993:2022)

# automatize the import of data
counter <- 1992
for (dataset in datasets) {
  filename <- paste0("Cleaned_datasetsV3/",dataset, ".csv")
  assign(paste0("d", counter, "_", counter+1), read.csv(filename))
  
  # Clean some typos 
  clean_typos(paste0("d", counter, "_", counter+1))
  
  counter <- counter + 1
}


##########################################
# 3 Degree                               #
##########################################

diameter_ <- numeric(0) # diameter
md_ <- numeric(0) # mean distance
density_ <- numeric(0) # density
max_edge <- numeric(0) # max_edge
mean_edge <- numeric(0) # mean_edge
plots <- list() # list of plots
plots2 <- list() # list os plots
clustering_ <-numeric(0) # clustering


intra_md <- numeric(0) # mean league mean distance

intra_dens <- numeric(0) # mean league density

intra_diam <- numeric(0) # mean league diameter

intra_clust <-numeric(0) # mean league clustering



mean_degree_ <- numeric(0) # mean degree
max_degree_ <- numeric(0) # max degree


plots_count <- list() # list os plots
plots_count2 <- list() # list os plots


counter <- 1992 # Initialize the counter


for (dataset in datasets){ # read all datasets
  filename <- paste0("d", counter, "_", counter+1) # create the name
  df<-get(filename) # take that dataset
  
  # apply fineTuning function
  result <- fineTuning(df)
  df_match <- result$df_match
  df_selezionato <- result$df_selezionato
  
  # list of the nodes to be removed
  remove_for_com_detect <- c("Africa", "Est_EU","Belgium","North_EU","Central_EU","free agents", "South America", "Turkey", "Russia", "Asia","North America",   "Italy", "Spain", "France", "Uk", "Portugal","Germany", "Netherlands" )

  
  # Remove them from 'df_selezionato' creating a df
  df_selezionato <-subset(df_selezionato, !(df_selezionato$club_name %in% remove_for_com_detect |     df_selezionato$club_involved_name %in% remove_for_com_detect))
  
  # Remove them from df_match
  df_match<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))
  
  # create the graph
  g <- graph.data.frame(df_selezionato, directed=TRUE)
  
  # add the fee and N attributes to each edge
  set.edge.attribute(g, "fee", index=E(g), value=as.numeric(df_selezionato$fee_cleaned))
  set.edge.attribute(g, "N", index=E(g), value=as.numeric(df_selezionato$count))
  
  # add the club_name value
  V(g)$club_name <- V(g)$name
  
  # add the league for each node
  V(g)$type <- df_match$league_name[match(V(g)$club_name, df_match$club_name)]
  
  # compute diameter
  val <- diameter(g, weights = NA)
  # store it
  diameter_ <- c(diameter_, val)
  
  # compute the measure 
  md<- mean_distance(g, weights = NA)
  # store it
  md_ <- c(md_, md)
  
  # compute the measure
  dens <- edge_density(g)
  # store it
  density_ <- c(density_, dens)
  
  # compute the measure
  max_e <- max(E(g)$fee_cleaned)
  # store it
  max_edge <- c(max_edge, max_e)
  
  # compute the measure
  mean_e <-mean(E(g)$fee_cleaned)
  # store it
  mean_edge <- c(mean_edge, mean_e)
  
  # compute the measure
  clust <- transitivity(g)
  # store it
  clustering_ <- c(clustering_, clust)
  
  
  # compute the measure and store it
  max_d <- max(degree(g))
  max_degree_ <- c(max_degree_, max_d)
  
  # compute the measure and store it
  mean_d <- mean(as.numeric(degree(g)))
  mean_degree_ <- c(mean_degree_, mean_d)
  
  
  # compute the measure for each different league
  result_clustering <- lapply(unique(V(g)$type), function(t) {
    subg <- induced_subgraph(g, which(V(g)$type == t))
    transitivity(subg)
  })
  # store the mean of leagues
  intra_clust<-c(intra_clust, mean(as.numeric(result_clustering)))
  
  
  # compute the measure for each different league
  result_diameter <- lapply(unique(V(g)$type), function(t) {
    subg <- induced_subgraph(g, which(V(g)$type == t))
    diameter(subg)
  })
  # store the mean of leagues
  intra_diam <- c(intra_diam, mean(as.numeric(result_diameter)))
  
  
  # compute the measure for each different league
  result_md <- lapply(unique(V(g)$type), function(t) {
    subg <- induced_subgraph(g, which(V(g)$type == t))
    mean_distance(subg, weights = NA)
  })
  # store the mean of leagues
  intra_md <- c(intra_md, mean(as.numeric(result_md)))
  
  
  # compute the measure for each different league
  result_dens <- lapply(unique(V(g)$type), function(t) {
    subg <- induced_subgraph(g, which(V(g)$type == t))
    edge_density(subg)
  })
  # store the mean of the leagues
  intra_dens <- c(intra_dens, mean(as.numeric(result_dens)))
  
  # assign the right names
  title<-paste0("Season"," ", counter, "/", counter+1)
  title2<-paste0("Season"," ", counter, "/", counter+1, "log-log")
  
  # Create the FEE plot
  p <- ggplot(data = data.frame(E(g)$fee_cleaned), aes(x = E.g..fee_cleaned)) +
    geom_histogram(fill = "#00BA38", color = "black", alpha = 0.5, binwidth = 4) +
    scale_x_continuous( expand = c(0,0)) +
    labs(title = title, x = "Transfer fee (in milions)", y = "Frequency") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
          axis.title.x = element_text(size = 12),
          axis.title.y = element_text(size = 12),
          axis.text = element_text(size = 10))
  
  # assign it 
  plots[[counter - 1991]] <- p

  
  # FEE Plots LOG-LOG
  
  G.degrees<- E(g)$fee_cleaned
  # Let's count the frequencies
  G.degree.histogram <- as.data.frame(table(G.degrees))
  G.degree.histogram[,1] <- as.numeric(G.degree.histogram[,1])
  
  # compute the plot
  p2 <- ggplot(G.degree.histogram, aes(x = G.degrees, y = Freq)) +
    geom_point() +
    scale_x_continuous("Degree\n",
                       breaks = c(1, 3, 10, 30, 100, 300),
                       trans = "log10") +
    scale_y_continuous("Frequency\n",
                       breaks = c(1, 3, 10, 30, 100, 300, 1000),
                       trans = "log10") +
    ggtitle(title) +
    theme_bw()
  
  # store it
  plots2[[counter - 1991]] <- p2
  
  
  
  # assign right names
  title_count<-paste0("Season"," ", counter, "/", counter+1)
  title_count2<-paste0("Season"," ", counter, "/", counter+1, "log-log")
  

  
  
  # create the plot
  p_count <- ggplot(data = data.frame(degree(g)), aes(x = degree.g.)) +
    geom_histogram(fill = "#CD4F39", color = "black", alpha = 0.8, binwidth = 4) +
    scale_x_continuous( expand = c(0,0)) +
    labs(title = title, x = "Number of operations", y = "Frequency") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
          axis.title.x = element_text(size = 12),
          axis.title.y = element_text(size = 12),
          axis.text = element_text(size = 10))
  
  # store in the list
  plots_count[[counter - 1991]] <- p_count

  
  # Count Plots LOG-LOG

  G.degrees <- degree(g)
  G.degree.histogram <- as.data.frame(table(G.degrees))
  G.degree.histogram[,1] <- as.numeric(G.degree.histogram[,1])
  
  # create the plot
  p_count2 <- ggplot(G.degree.histogram, aes(x = G.degrees, y = Freq)) +
    geom_point() +
    scale_x_continuous("Degree\n",
                       breaks = c(1, 3, 10, 30, 100, 300),
                       trans = "log10") +
    scale_y_continuous("Frequency\n",
                       breaks = c(1, 3, 10, 30, 100, 300, 1000),
                       trans = "log10") +
    ggtitle(title) +
    theme_bw()
  
  # store it
  plots_count2[[counter - 1991]] <- p_count2
  
  
  # increment the counter
  counter <- counter + 1
  
}

max_degree_
mean_degree_

max_edge
mean_edge

diameter_
md_
density_
clustering_ 


# saving plots:

# edges
for (i in 1:30) {
  ggsave(filename = paste("plot_ad_alta_qualita_", 1992 + i, ".png", sep = ""), 
         plot = plots[[i]], 
         width = 8, height = 6, dpi = 800)
}

# edges loglog
for (i in 1:30) {
  ggsave(filename = paste("plot_loglog_", 1992 + i, ".png", sep = ""), 
         plot = plots2[[i]], 
         width = 8, height = 6, dpi = 800)
}


# degree
for (i in 1:30) {
  ggsave(filename = paste("degree_", 1992 + i, ".png", sep = ""), 
         plot = plots_count[[i]], 
         width = 8, height = 6, dpi = 800)
}

# degree loglog
for (i in 1:30) {
  ggsave(filename = paste("degree_loglog_", 1992 + i, ".png", sep = ""), 
         plot = plots_count2[[i]], 
         width = 8, height = 6, dpi = 800)
}



#### max edge fees  Plot####

years <- paste(1992:2021, "/", 1993:2022, sep = "")

# create the dataset 
df_MAxedge <- data.frame(time = years,
                         value = max_edge)

# plot
ggplot(data = df_MAxedge, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Maximum edge fee over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, 250))+
  scale_color_manual(values = c("Unweighted" = "#1874CD")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 


# save
ggsave("Maximum edge fee over time.png", plot = last_plot(), dpi = 800, width = 297, height =210, units = "mm")


####### plot max and mean degree

# create the datasets
df_max_degree <- data.frame(time = years,
                            value = max_degree_)
df_mean_degree <- data.frame(time = years,
                             value = mean_degree_)



# store the first plot
p1de<- ggplot(data = df_max_degree, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Max degree over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(8, 30))+
  scale_color_manual(values = c("Unweighted" = "#9ACD32")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 

# store the second plot
p2de<- ggplot(data = df_mean_degree, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Mean degree over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, 10))+
  scale_color_manual(values = c("Unweighted" = "#6959CD")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 


# put theme in a grid
grid_plotdeg <- grid.arrange(p1de, p2de, ncol = 1, nrow = 2)


# save the plot
ggsave("Max_mean_degree.png", plot = grid_plotdeg, dpi = 800, width = 210, height =297, units = "mm")




###  plot diameter, mean distance, density and clustering in overall network ###
# 4 plot in 1:

# create datasets
df_diameter <- data.frame(time = years,
                          value = diameter_)
df_md <- data.frame(time = years,
                    value = md_)
df_density <- data.frame(time = years,
                         value = density_)
df_clustering <- data.frame(time = years,
                            value = clustering_)

# store each plot in a variable

p1<- ggplot(data = df_diameter, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Diameter over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(8, 22))+
  scale_color_manual(values = c("Unweighted" = "#008B00")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 

p2<- ggplot(data = df_md, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Mean Distance over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, 10))+
  scale_color_manual(values = c("Unweighted" = "#8B1A1A")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 


p3<- ggplot(data = df_density, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Density over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0.01, 0.05))+
  scale_color_manual(values = c("Unweighted" = "#EEC900")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 

p4<- ggplot(data = df_clustering, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Mean Clustering over time", hjust =0.5) +
  theme_minimal() +
  #scale_y_continuous(limits = c(0.05, 0.2))+
  scale_color_manual(values = c("Unweighted" = "#EE6AA7")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 


# create the grid
grid_plot <- grid.arrange(p1, p2, p3, p4, ncol = 2, nrow = 2)


# save it
ggsave("4M.png", plot = grid_plot, dpi = 800, width = 297, height =210, units = "mm")






###  plot diameter, mean distance, density and clustering in each league network ###

# create the datasets

df_diameter2 <- data.frame(time = years,
                           value = intra_diam)
df_md2 <- data.frame(time = years,
                     value = intra_md)
df_density2 <- data.frame(time = years,
                          value = intra_dens)
df_clustering2 <- data.frame(time = years,
                             value = intra_clust)

# store each plot in a variable

p_1<- ggplot(data = df_diameter2, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Diameter over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(4, 22))+
  scale_color_manual(values = c("Unweighted" = "#008B00")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 

p_2<- ggplot(data = df_md2, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Mean Distance over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, 10))+
  scale_color_manual(values = c("Unweighted" = "#8B1A1A")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 


p_3<- ggplot(data = df_density2, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Density over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0.01, 0.15))+
  scale_color_manual(values = c("Unweighted" = "#EEC900")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 

p_4<- ggplot(data = df_clustering2, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  #geom_path() +
  geom_line(size = 2) +
  labs(x = "Season", y = "Value", title = "Mean Clustering over time (Intra", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(0.1, 0.3))+
  scale_color_manual(values = c("Unweighted" = "#EE6AA7")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position = "none",plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) 


# create the grid
grid_plot2 <- grid.arrange(p_1, p_2, p_3, p_4, ncol = 2, nrow = 2)


# save the grid
ggsave("4M_Intra.png", plot = grid_plot2, dpi = 800, width = 297, height =210, units = "mm")





# two histograms plot fined-tuned
ggplot(data = data.frame(E(g)$fee_cleaned), aes(x = E.g..fee_cleaned)) +
  geom_histogram(fill = "#00BA38", color = "black", alpha = 0.5, binwidth = 1) +
  scale_x_continuous( expand = c(0,0)) +
  labs(title = "Season 1993/1994", x = "Transfer fee (in milions)", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.title.x = element_text(size = 12),
        axis.title.y = element_text(size = 12),
        axis.text = element_text(size = 10))



ggplot(data = data.frame(degree(g)), aes(x = degree.g.)) +
  geom_histogram(fill = "#CD4F39", color = "black", alpha = 0.8, binwidth = 2) +
  scale_x_continuous( expand = c(0,0)) +
  labs(title = "Season 2017/2018", x = "Number of operations", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.title.x = element_text(size = 12),
        axis.title.y = element_text(size = 12),
        axis.text = element_text(size = 10))







##########################################
# 4 Modularity                           #
##########################################

# initialize the values
modularity_W<- numeric(0) # W= Fees
modularity_<- numeric(0) # unweigthed
modularity_N <- numeric(0) # W= number of operations


# reset the counter
counter <- 1992


for (dataset in datasets){ # read all datasets
  filename <- paste0("d", counter, "_", counter+1)
  df<-get(filename) # take the dataset
  
  # apply fineTuning
  result <- fineTuning(df)
  df_match <- result$df_match
  df_selezionato <- result$df_selezionato
  remove_for_com_detect <- c("Est_EU","Belgium","North_EU","Central_EU","free agents", "South America", "Turkey", "Russia", "Asia","North America", "Africa")
  
  df_selezionato <-subset(df_selezionato, !(df_selezionato$club_name %in% remove_for_com_detect |     df_selezionato$club_involved_name %in% remove_for_com_detect))
  
  # Remove them from df_match
  df_match<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))
  
  g <- graph.data.frame(df_selezionato, directed=TRUE)
  
  # add the attributes
  set.edge.attribute(g, "fee", index=E(g), value=as.numeric(df_selezionato$fee_cleaned))
  set.edge.attribute(g, "N", index=E(g), value=as.numeric(df_selezionato$count))
  
  V(g)$club_name <- V(g)$name
  V(g)$type <- df_match$league_name[match(V(g)$club_name, df_match$club_name)]
  
  # compute each modularity type  and assign it
  
  val <- modularity(g, as.numeric(as.factor(V(g)$type)))
  modularity_ <- c(modularity_, val)
  
  
  val_W <- modularity(g , as.numeric(as.factor(V(g)$type)) , weights=E(g)$fee_cleaned)
  modularity_W <- c(modularity_W , val_W)
  
  val_N <- modularity(g , as.numeric(as.factor(V(g)$type)) , weights=E(g)$count)
  modularity_N <- c(modularity_N , val_N)
  
  # increment the counter
  counter <- counter + 1
}

# create the column years for plotting

years <- paste(1992:2021, "/", 1993:2022, sep = "")

# Create the datasets for plotting

df <- data.frame(time = years,
                 value = modularity_)

df2 <- data.frame(time = years,
                  value = modularity_W)

df3 <- data.frame(time = years,
                  value = modularity_N)
# plot the values
ggplot(data = df, aes(x = time, y = value, color = "Unweighted", group = 1)) +
  geom_line(size = 2) +
  geom_point(size = 3) +
  geom_line(data = df2, aes(x = time, y = value, color = "W = fees"), size = 2) +
  geom_point(data = df2, aes(x = time, y = value, color = "W = fees"), size = 3) +
  geom_line(data = df3, aes(x = time, y = value, color = "W = # operations"), size = 2) +
  geom_point(data = df3, aes(x = time, y = value, color = "W = # operations"), size = 3) +
  labs(x = "Season", y = "Value", title = "Modularity evolution over time", hjust =0.5) +
  theme_minimal() +
  scale_y_continuous(limits = c(-0.5, 1))+
  scale_color_manual(values = c("Unweighted" = "#104E8B", "W = fees" = "#CD4F39", "W = # operations" = "#FFD700")) +
  theme(axis.text.x = element_text(angle = 70, hjust = 1, size=10), legend.position =  c(0.9, 0.9),plot.title = element_text(size = 22),legend.background = element_rect(fill = "white"), plot.background =element_rect(fill = "white") ) +
  
  guides(color = guide_legend(title = "Modularity Type"))

# Save it
ggsave("Modularity_lines.png", plot = last_plot(), dpi = 800, width = 297, height =210, units = "mm")








##########################################
# 5 graph plot                           #
##########################################

# apply finetuning
result <- fineTuning(d2017_2018)
df_match <- result$df_match
df_selezionato <- result$df_selezionato


remove_for_com_detect <- c("Est_EU","Belgium","North_EU","Central_EU","free agents", "South America", "Turkey", "Russia", "Asia","North America", "Africa", "Uk", "Italy", "France", "Germany", "Portugal", "Netherlands", "Spain")

# Remove them from df
df_selezionato <-subset(df_selezionato, !(df_selezionato$club_name %in% remove_for_com_detect | df_selezionato$club_involved_name %in% remove_for_com_detect))

# Remove them from df_match
df_match<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))

# build the graph
g <- graph.data.frame(df_selezionato, directed=TRUE)

# add fee attributes
set.edge.attribute(g, "fee", index=E(g), value=as.numeric(df_selezionato$fee_cleaned))

# add names and league
V(g)$club_name <- V(g)$name
V(g)$type <- df_match$league_name[match(V(g)$club_name, df_match$club_name)]

# correct the lables spaces
V(g)$label <- sapply(strsplit(V(g)$club_name, " "), function(x) paste(x, collapse="\n"))


# assign the colors
colors <- c("#FF0000" ,"#0092FF","#FFDB00","#49FF00","#00FF92","#FF00DB", "#4900FF")
V(g)$color <- colors[match(V(g)$type, unique(V(g)$type))]
V(g)$degree <- degree(g)


# assign to each edge the width 
vec_W <- numeric()
for (i in E(g)$fee_cleaned){
  val<- classify_edge_width(i)
  vec_W <- c(vec_W, val)
}

# assign to each edge the color
vec_c <- numeric()
for (i in E(g)$fee_cleaned){
  val<- classify_edge_color(i)
  vec_c <- c(vec_c, val)
}

E(g)$width <- vec_W
E(g)$color <- vec_c



# plot G by tkplot()
tkplot(g, vertex.label.color="black", edge.arrow.size=0.8, vertex.label.size = "none", vertex.label.cex=1, edge.curved=0.4 ,vertex.size=24, show.labels = FALSE)


# build the right legend : plot(NULL ,xaxt='n',yaxt='n',bty='n',ylab='',xlab='', xlim=0:1, ylim=0:1)
legend("topleft", legend =c('Bundesliga', 'Ligue 1', 'Serie A',
                            'Eredivisie', 'Primiera Division', 'Premier League', 'Liga Nos'), pch=16, pt.cex=3, cex=1.5, bty='n',
       col = c("#FF0000" ,"#0092FF","#FFDB00","#49FF00","#00FF92"  ,"#FF00DB", "#4900FF"))
mtext("League", at=0.2, cex=2)


##########################
# 6 degree distribution  #
##########################


# Ridgelines

mean_transfers <- numeric(0)
means_money_transfers<- numeric(0)
counter <- 1992
df5 <- data.frame(x = as.numeric(), 
                  group = factor())
counter_flow <- 0
for (dataset in datasets){ # read all datasets
  filename <- paste0("d", counter, "_", counter+1)
  df<-get(filename) # take the dataset
  
  # apply fineTuning
  result <- fineTuning(df)
  df_match <- result$df_match
  df_selezionato <- result$df_selezionato
  remove_for_com_detect <- c("fhgf")

  # Remove them 
  df_selezionato <-subset(df_selezionato, !(df_selezionato$club_name %in% remove_for_com_detect |     df_selezionato$club_involved_name %in% remove_for_com_detect))
  
  # Remove them from df_match
  df_match<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))
  

  g <- graph.data.frame(df_selezionato, directed=TRUE)
  
  # Attributes
  set.edge.attribute(g, "fee", index=E(g), value=as.numeric(df_selezionato$fee_cleaned))
  set.edge.attribute(g, "N", index=E(g), value=as.numeric(df_selezionato$count))
  
  V(g)$club_name <- V(g)$name
  V(g)$type <- df_match$league_name[match(V(g)$club_name, df_match$club_name)]
  
  
  # just to see
  title<-paste0("Season"," ", counter, "/", counter+1)
  title2<-paste0("Season"," ", counter, "/", counter+1)
  assign(title,ggplot(data = data.frame(E(g)$fee_cleaned), aes(x = E.g..fee_cleaned)) +
           geom_histogram(fill = "#00BA38", color = "black", alpha = 0.5, binwidth = 1) +
           scale_x_continuous( expand = c(0,0)) +
           labs(title = title, x = "Valori", y = "Frequenza") +
           theme_minimal() +
           theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
                 axis.title.x = element_text(size = 12),
                 axis.title.y = element_text(size = 12),
                 axis.text = element_text(size = 10))) 

  df_temp <- data.frame(x = as.numeric(E(g)$fee_cleaned), 
                        group = paste0(counter, "/", counter+1), depth = (counter_flow/5) + 1)
  
  if (counter_flow %% 5 == 0) {
    df5 <- rbind(df5, df_temp)
  }
  
  
  
  # increment the counters
  counter <- counter + 1
  counter_flow<- counter_flow +1
}

# plot the ridgelines
ggplot(df5, aes(x = x, y = group, fill = group)) +
  geom_density_ridges(alpha = 0.5) +
  labs(x = "Values", y = "Density") +
  scale_fill_brewer(palette = "Dark2") +
  theme(legend.position = "none") +
  theme_minimal()


##########################################
# 7 Centrality                           #
##########################################

# create all the empty variables to append the values
degre_centr <- numeric(0)
bet_vect <- numeric(0)
page_vect <- numeric(0)
results <- list()
edge_bet<- numeric(0)

counter<- 1992
for (dataset in datasets){ # read all datasets
  filename <- paste0("d", counter, "_", counter+1)
  df<-get(filename) # take the dataset
  
  # apply fineTuning
  result <- fineTuning(df)
  df_match <- result$df_match
  df_selezionato <- result$df_selezionato
  remove_for_com_detect <- c("Est_EU","Belgium","North_EU","Central_EU","free agents", "South America", "Turkey", "Russia", "Asia","North America",   "Italy", "Spain", "France", "Uk", "Portugal","Germany", "Netherlands")
 
  # Remove them 
  df_selezionato <-subset(df_selezionato, !(df_selezionato$club_name %in% remove_for_com_detect |     df_selezionato$club_involved_name %in% remove_for_com_detect))
  
  # Remove them from df_match
  df_match<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))
  

  g <- graph.data.frame(df_selezionato, directed=TRUE)
  
  # Attribtus
  set.edge.attribute(g, "fee", index=E(g), value=as.numeric(df_selezionato$fee_cleaned))
  set.edge.attribute(g, "N", index=E(g), value=as.numeric(df_selezionato$count))
  
  V(g)$club_name <- V(g)$name
  V(g)$type <- df_match$league_name[match(V(g)$club_name, df_match$club_name)]
  
  # degree centr
  degree_centrality <- degree(g, mode = "out",)
  degre_centr <- c(degre_centr, which.max(degree_centrality))
  
  # betwennes
  betweenness_centrality <- betweenness(g)
  sorted_data <- sort(betweenness_centrality , decreasing=TRUE)
  h<-which.max(betweenness_centrality)
  top_3 <- sorted_data[1:3] # append the top 3
  results[[length(results)+1]] <- top_3
  
  
  bet_vect <- c(bet_vect, h)
  
  # edge_bet
  e_b<- edge.betweenness(g)
  edge_bet <- c(edge_bet, E(g)[which.max(e_b)])
  
  # page_rank
  page_rank <- page.rank(g)
  page_vect <- c(page_vect, which.max(page_rank$vector))
  
  # increment the counter
  counter <- counter + 1
}

results
degre_centr
bet_vect
page_vect
edge_bet


# betwenness plot #
top_ten <- results[21:30]
mean_values <- sapply(top_ten, mean)
df <- data.frame(mean_values, position=1:10)

start_year <- 2012
end_year <- 2022
years <- paste(start_year:(end_year-1), "/", start_year+1:end_year, sep="")

# change columns names
df$year <- years[0:10]
df$position <- NULL
colnames(df) <- c("y", "x")

# plot
ggplot(df, aes(x = x, y = y)) +
  geom_segment(aes(x = x, xend = x, y = 0, yend = y), col = "#1C86EE", size = 1.5) +
  geom_point(aes(x = x, y = y), size = 4, fill = "red", col = "white") +
  coord_flip() +
  ggtitle("Top 3 nodes by Betweness Centrality") +
  xlab("Season") +
  ylab("Values") +
  scale_y_continuous(limits = c(0, 2400), expand = c(0, 0)) +
  theme_minimal() + theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

# store it
ggsave("Bet_Centrality.png", plot = last_plot(), dpi = 800)


##########################################
# 8 STEAM PLOT                           #
##########################################

datasets <- paste0("d",1993:2021, "_", 1994:2022)

# automatize the import of data
counter <- 1992
df_Steam_plot<- d1992_1993
for (dataset in datasets) {
  df<- get(dataset)
  temp<-rbind(df,df_Steam_plot)
  df_Steam_plot <-temp
}
# create the right dataset
df_Steam_plot

df_sts <- aggregate(fee_cleaned ~  league_name + year  , data = df_Steam_plot, FUN = sum, na.rm = TRUE)

# select the colors
cols <- c("#FFB400",  "#EE9A49", "#FF4500","#C20008", "#13AFEF", "#008B00", "#68228B")

# plot
ggplot(df_sts, aes(x = year, y = fee_cleaned, fill = league_name)) +
  geom_stream(color = 1, lwd = 0.25) +
  scale_fill_manual(values = cols) +
  theme_minimal() +
  guides(fill = guide_legend(title = "League"))+
  ggtitle("Stream Plot of Transfer Fees by League and Year")+
  xlab("Year") +
  ylab("Transfer Fee (in millions)")

# save it
ggsave("streamplot_hat.png", plot = last_plot(), dpi = 800)


##########################################
# 9 Community detection                  #
##########################################

result <- fineTuning(d1992_1993)
df_match <- result$df_match
df_selezionato <- result$df_selezionato
remove_for_com_detect <- c("Est_EU","Belgium","North_EU","Central_EU","free agents", "South America", "Turkey", "Russia", "Asia","North America", "Africa")

df_selezionato <-subset(df_selezionato, !(df_selezionato$club_name %in% remove_for_com_detect |     df_selezionato$club_involved_name %in% remove_for_com_detect))


df_match<-subset(df_match, !(df_match$club_name %in% remove_for_com_detect))

# build graph
g <- graph.data.frame(df_selezionato, directed=F)


set.edge.attribute(g, "fee", index=E(g), value=as.numeric(df_selezionato$fee_cleaned))
set.edge.attribute(g, "N", index=E(g), value=as.numeric(df_selezionato$count))

V(g)$club_name <- V(g)$name
V(g)$type <- df_match$league_name[match(V(g)$club_name, df_match$club_name)]

# simplify it
g_cd <- simplify(g)

# Get the scores
fcg <- cluster_optimal(g_cd)
V(g_cd)$community <- membership(fcg)

# plot the communities
plot(g_cd, vertex.color = V(g_cd)$community, vertex.size = 4, asp = 0, edge.arrow.size=0.4,  vertex.label= NA, vertex.label.dist=1, vertex.label.size = 0.3)

membership(fcg)

comparison_table <- table(V(g_cd)$type, V(g_cd)$community)

# comparision real-predicted
comparison_table
