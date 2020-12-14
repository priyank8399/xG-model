library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)

shot_events <- fromJSON("events/events_European_Championship.json") %>%
  filter(eventId == 10)


shot_tags <- select(shot_events, tags, positions, playerId) %>%
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

# Convert x, y coordinates to metres
shot_tags[c("x1")] <- (shot_tags[c("x1")]/100) * 105
shot_tags[c("y1")] <- (shot_tags[c("y1")]/100) * 68

# Positions of goalposts from bottom right of the pitch
post1_pos <- 30.34
post2_pos <- 37.66

# Compute distances to each goalpost
shot_tags$distance_to_goal1 <- sqrt((105 - shot_tags[c("x1")])^2 + (post1_pos - shot_tags[c("y1")])^2)
shot_tags$distance_to_goal2 <- sqrt((105 - shot_tags[c("x1")])^2 + (post2_pos - shot_tags[c("y1")])^2)

# Compute the angle between the player and goalposts
shot_tags$angle_to_goal <- acos((shot_tags$distance_to_goal2^2 + shot_tags$distance_to_goal1^2 - 7.32^2)/(2*shot_tags$distance_to_goal1*shot_tags$distance_to_goal2)) * 180/pi

logistic <- glm(is_goal ~ ., data = shot_tags, family = "binomial")

logistic$coefficients
