library(jsonlite)
library(dplyr)
library(tidyr)
library(ggsoccer)
library(ggplot2)
library(tibble)
library(pROC)

path <- "C:/Users/Izan Ahmed/DataScienceFinal/xG-model/events/events_England.json"

shot_events <- fromJSON(path)


players <- fromJSON("C:\Users\Izan Ahmed\Downloads\DataScienceFinal\xG-model\players.json") %>% 
  select(wyId, foot, lastName)


shot_pass_events <- shot_events[FALSE,]
shot_pass_events <- add_column(shot_pass_events, preceding_pass = NA)
shot_events <- add_column(shot_events, preceding_pass = NA)
j = 1
for(i in 1:nrow(shot_events)) {
  if(shot_events[i,"eventId"] == 10 && (shot_events[i-1, "eventId"] == 8 | shot_events[i-1, "eventId"] == 1)) {
    shot_pass_events <- rbind(shot_pass_events, shot_events[i,])
    shot_pass_events[j, "preceding_pass"] <- shot_events[i-1, "subEventName"]
    j = j + 1
  }
}

shot_tags <- select(shot_pass_events, tags, positions, playerId, matchId, eventSec, eventId, preceding_pass) %>%
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
                    is_body = ifelse(id1==403 | id2==403 | id3==403 | id4==403 | id5 == 403 | id6 == 403, 1, 0),
                    is_counter = ifelse(id1==1901 | id2==1901 | id3==1901 | id4==1901 | id5 == 1901 | id6 == 1901, 1, 0), 
                    is_through = ifelse(preceding_pass == "Smart pass", 1, 0)) %>%
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

shot_tags$foot <- NULL


new_shots <- select(shot_tags, distance_to_goal_center, angle_to_goal, is_goal, is_counter, is_dominant, is_through)

# new_shots2 <- select(shot_tags, distance_to_goal_center, angle_to_goal, is_goal)
# 
# 
# logistic <- glm(is_goal ~ ., data = new_shots2, family = "binomial")
logistic <- glm(is_goal ~ ., data = new_shots, family = "binomial")
summary(logistic)
# summary(logistic2)

## --------------------------------------------------------------------------####
### TESTING DATASET


test_shot_events <- fromJSON("C:/Users/Izan Ahmed/DataScienceFinal/xG-model/events/events_France.json")

test_shot_pass_events <- test_shot_events[FALSE,]
test_shot_pass_events <- add_column(test_shot_pass_events, preceding_pass = NA)
test_shot_events <- add_column(test_shot_events, preceding_pass = NA)
j = 1
for(i in 1:nrow(shot_events)) {
  if(test_shot_events[i,"eventId"] == 10 && (test_shot_events[i-1, "eventId"] == 8 | test_shot_events[i-1, "eventId"] == 1)) {
    test_shot_pass_events <- rbind(test_shot_pass_events, test_shot_events[i,])
    test_shot_pass_events[j, "preceding_pass"] <- test_shot_events[i-1, "subEventName"]
    j = j + 1
  }
}

test_shot_tags <- select(test_shot_pass_events, tags, positions, playerId, matchId, eventSec, eventId, preceding_pass) %>%
  unnest_wider(tags) %>%
  unnest_wider(positions) %>%
  unnest_wider(id, names_sep = "") %>%
  unnest_wider(y, names_sep = "") %>%
  unnest_wider(x, names_sep = "") %>%
  select(-y2, -x2)

test_shot_tags <- mutate(test_shot_tags, is_goal = ifelse((id1==101 | id2==101 | id3==101 | id4==101 | id5 == 101 | id6 == 101), 1, 0),
                    is_blocked = ifelse(id1==2101 | id2==2101 | id3==2101 | id4==2101 | id5 == 2101 | id6 == 2101, 1, 0),
                    is_left = ifelse(id1==401 | id2==401 | id3==401 | id4==401 | id5 == 401 | id6 == 401, 1, 0),
                    is_right = ifelse(id1==402 | id2==402 | id3==402 | id4==402 | id5 == 402 | id6 == 402, 1, 0),
                    is_body = ifelse(id1==403 | id2==403 | id3==403 | id4==403 | id5 == 403 | id6 == 403, 1, 0),
                    is_counter = ifelse(id1==1901 | id2==1901 | id3==1901 | id4==1901 | id5 == 1901 | id6 == 1901, 1, 0), 
                    is_through = ifelse(preceding_pass == "Smart pass", 1, 0)) %>%
  select(-id1, -id2, -id3, -id4, -id5, -id6)

test_shot_tags[is.na(shot_tags)] <- 0


test_shot_tags <- filter(shot_tags, is_blocked == 0) %>%
  select(-is_blocked)


test_shot_tags <- inner_join(test_shot_tags, players, by="playerId")

test_shot_tags$wyId <- NULL

test_shot_tags$x_wyscout <- test_shot_tags$x1
test_shot_tags$y_wyscout <- test_shot_tags$y1

# Convert x, y coordinates to metres
test_shot_tags$x1 <- (test_shot_tags$x1/100) * 105
test_shot_tags$y1 <- (test_shot_tags$y1/100) * 68

# Positions of goalposts from bottom right of the pitch
post1_pos <- 30.34
post2_pos <- 37.66

# Compute distances to each goalpost
test_shot_tags$distance_to_post1 <- sqrt((105 - (test_shot_tags$x1))^2 + (post1_pos - (test_shot_tags$y1))^2)
test_shot_tags$distance_to_post2 <- sqrt((105 - (test_shot_tags$x1))^2 + (post2_pos - (test_shot_tags$y1))^2)

test_shot_tags$distance_to_goal_center <- sqrt((105 - (test_shot_tags$x1))^2 + (34 - (test_shot_tags$y1))^2)

# Compute the angle between the player and goalposts
test_shot_tags$angle_to_goal <- acos((test_shot_tags$distance_to_post2^2 + 
                                        test_shot_tags$distance_to_post1^2 - 7.32^2)/(2*test_shot_tags$distance_to_post1*test_shot_tags$distance_to_post2)) * (180/pi)

# Come back to this to figure out why we have a NaN
test_shot_tags <- filter(test_shot_tags, !is.nan(angle_to_goal))

test_shot_tags$is_dominant <- ifelse((test_shot_tags$is_left == 1 & test_shot_tags$foot == "left") | 
                                  (test_shot_tags$is_right == 1 & test_shot_tags$foot == "right"), 1, 0)


# shot_tags$lastName <- NULL
test_shot_tags$foot <- NULL
# shot_tags$playerId <- NULL


test_new_shots <- select(test_shot_tags, distance_to_goal_center, angle_to_goal, is_goal, is_counter, is_dominant, is_through)

# test_new_shots2 <- select(test_shot_tags, distance_to_goal_center, angle_to_goal, is_goal)

test_new_shots$prediction <- predict(logistic, test_new_shots, type="response")

g <- roc(is_goal ~ prediction, data = test_new_shots)

plot(g)

auc(g)
# logistic <- glm(is_goal ~ ., data = new_shots2, family = "binomial")
# logistic2 <- glm(is_goal ~ ., data = new_shots, family = "binomial")
# summary(logistic)
# summary(logistic2)

# 
# logit <- logistic$coefficients
# 
# predicted_data <- data.frame(probability_of_goal=logistic$fitted.values, is_goal=new_shots$is_goal)
# predicted_data$distance <- new_shots$distance_to_goal_center
# predicted_data$matchId <- shot_tags$matchId
# predicted_data$lastName <- shot_tags$lastName
# predicted_data$eventSec <- shot_tags$eventSec
# predicted_data$angle <- shot_tags$angle_to_goal
# predicted_data$x <- shot_tags$x_wyscout
# predicted_data$y <- shot_tags$y_wyscout
# predicted_data$is_through <- shot_tags$is_through
# predicted_data$is_counter <- shot_tags$is_counter
# predicted_data$preceding_pass <- shot_tags$preceding_pass
# 
# predicted_data <- predicted_data[order(predicted_data$probability_of_goal, decreasing = TRUE),]
# 
# predicted_data$rank <- 1:nrow(predicted_data)
# 
# ggplot(data=predicted_data, aes(x=distance, y=probability_of_goal)) + geom_point(aes(color=angle), alpha=1, shape=4, stroke=2)+
#   xlab("Distance to goal (m)")+
#   ylab("Predicted Probability of scoring a goal")