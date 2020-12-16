library(jsonlite)
library(dplyr)
library(tidyr)
library(ggsoccer)
library(ggplot2)

shot_events <- fromJSON("events/events_England.json") %>%
  filter(eventId == 10)


players <- fromJSON("players.json") %>% 
  select(wyId, foot, lastName)




shot_tags <- select(shot_events, tags, positions, playerId, matchId, eventSec) %>%
  unnest_wider(tags) %>%
  unnest_wider(positions) %>%
  unnest_wider(id, names_sep = "") %>%
  unnest_wider(y, names_sep = "") %>%
  unnest_wider(x, names_sep = "") %>%
  select(-y2, -x2)

shot_tags <- mutate(shot_tags, is_goal = ifelse((id1==101 | id2==101 | id3==101 | id4==101 | id5 == 101 | id6 == 101), 1, 0),
            is_blocked = ifelse(id1==2101 | id2==2101 | id3==2101 | id4==2101 | id5 == 2101 | id6 == 2101, 1, 0),
            is_left = ifelse(id1==401 | id2==401 | id3==401 | id4==401 | id5 == 401 | id6 == 401, 1, 0),
            is_right = ifelse(id1==402 | id2==402 | id3==402 | id4==402 | id5 == 402 | id6 == 402, 1, 0),
            is_body = ifelse(id1==403 | id2==403 | id3==403 | id4==403 | id5 == 403 | id6 == 403, 1, 0)) %>%
  select(-id1, -id2, -id3, -id4, -id5, -id6)

shot_tags[is.na(shot_tags)] <- 0

shot_tags <- filter(shot_tags, is_blocked == 0) %>%
  select(-is_blocked)

players$playerId <- players$wyId

shot_tags <- inner_join(shot_tags, players, by="playerId")

shot_tags$wyId <- NULL

shot_tags$x_wyscout <- shot_tags$x1
shot_tags$y_wyscout <- shot_tags$y1

# Convert x, y coordinates to metres
shot_tags$x1 <- (shot_tags$x1/100) * 105
shot_tags$y1 <- (shot_tags$y1/100) * 68

# Positions of goalposts from bottom right of the pitch
post1_pos <- 30.34
post2_pos <- 37.66

# Compute distances to each goalpost
shot_tags$distance_to_post1 <- sqrt((105 - (shot_tags$x1))^2 + (post1_pos - (shot_tags$y1))^2)
shot_tags$distance_to_post2 <- sqrt((105 - (shot_tags$x1))^2 + (post2_pos - (shot_tags$y1))^2)

shot_tags$distance_to_goal_center <- sqrt((105 - (shot_tags$x1))^2 + (34 - (shot_tags$y1))^2)

# Compute the angle between the player and goalposts
shot_tags$angle_to_goal <- acos((shot_tags$distance_to_post2^2 + 
                                   shot_tags$distance_to_post1^2 - 7.32^2)/(2*shot_tags$distance_to_post1*shot_tags$distance_to_post2)) * (180/pi)

# Come back to this to figure out why we have a NaN
shot_tags <- filter(shot_tags, !is.nan(angle_to_goal))

shot_tags$is_dominant <- ifelse((shot_tags$is_left == 1 & shot_tags$foot == "left") | 
                                  (shot_tags$is_right == 1 & shot_tags$foot == "right"), 1, 0)


# shot_tags$lastName <- NULL
shot_tags$foot <- NULL
# shot_tags$playerId <- NULL


new_shots <- select(shot_tags, distance_to_goal_center, angle_to_goal, is_goal)

logistic <- glm(is_goal ~ ., data = new_shots, family = "binomial")

logit <- logistic$coefficients

predicted_data <- data.frame(probability_of_goal=logistic$fitted.values, is_goal=new_shots$is_goal[1:6178])
predicted_data$distance <- new_shots$distance_to_goal_center
predicted_data$matchId <- shot_tags$matchId
predicted_data$lastName <- shot_tags$lastName
predicted_data$eventSec <- shot_tags$eventSec
predicted_data$angle <- shot_tags$angle_to_goal
predicted_data$x <- shot_tags$x_wyscout
predicted_data$y <- shot_tags$y_wyscout

predicted_data <- predicted_data[order(predicted_data$probability_of_goal, decreasing = TRUE),]

predicted_data$rank <- 1:nrow(predicted_data)



ggplot(data=predicted_data, aes(x=distance, y=probability_of_goal)) + geom_point(aes(color=angle), alpha=1, shape=4, stroke=2)+
  xlab("Distance to goal (m)")+
  ylab("Predicted Probability of scoring a goal")

write.csv(predicted_data, file = "predicted_data.csv")
