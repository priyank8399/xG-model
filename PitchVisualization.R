library(jsonlite)
library(dplyr)
library(tidyr)
library(ggsoccer)
library(ggplot2)
library("viridis")
library(RColorBrewer)

shots <- read.csv("predicted_data_model3.csv")

# Pitch visualization code from https://github.com/Dato-Futbol/xg-model/blob/master/04code_evaluate_use_models.R
ggplot(data = shots, aes(x= x, y = y)) + 
  annotate_pitch(colour = "white",
                 fill   = "black",
                 limits = FALSE) +
  theme_pitch() +
  theme(plot.background = element_rect(fill = "black"),
        title = element_text(colour = "white")) +
  coord_flip(xlim = c(50, 100),
             ylim = c(0, 100)) +
  geom_tile(aes(fill = probability_of_goal)) +
  scale_fill_gradientn(colours = rev(brewer.pal(11, "RdYlBu"))) +
  theme(legend.text = element_text(color = "white", size = 8, face = "plain"),
        legend.background = element_rect(fill = "black"),
        legend.key = element_rect(fill = "black", color = "black")) +
  labs(fill = "xG") +
  ggtitle("Expected goals model (Distance, Angle, Counter Attack, Dominant foot)")



