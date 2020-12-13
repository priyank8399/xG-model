library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)

shot_events <- fromJSON("events/events_European_Championship.json") %>%
  filter(eventId == 10)


shot_tags <- select(shot_events, tags, positions) %>%
  unnest_wider(tags) %>%
  unnest_wider(positions) %>%
  unnest_wider(id, names_sep = "") %>%
  unnest_wider(y, names_sep = "") %>%
  unnest_wider(x, names_sep = "") %>%
  select(-y2, -x2)


# cols = c("id1", "id2", "id3", "id4", "id5", "id6")
# tags2 <- a %>%
#   mutate(is_goal = ifelse(a[cols] == 201, 1, 0))

shot_tags <- mutate(shot_tags, is_goal = ifelse((id1==101 | id2==101 | id3==101 | id4==101 | id5 == 101 | id6 == 101), 1, 0),
            is_blocked = ifelse(id1==2101 | id2==2101 | id3==2101 | id4==2101 | id5 == 2101 | id6 == 2101, 1, 0),
            is_left = ifelse(id1==401 | id2==401 | id3==401 | id4==401 | id5 == 401 | id6 == 401, 1, 0),
            is_right = ifelse(id1==402 | id2==402 | id3==402 | id4==402 | id5 == 402 | id6 == 402, 1, 0),
            is_body = ifelse(id1==403 | id2==403 | id3==403 | id4==403 | id5 == 403 | id6 == 403, 1, 0)) %>%
  select(-id1, -id2, -id3, -id4, -id5, -id6)

shot_tags[is.na(shot_tags)] <- 0

logistic <- glm(is_goal ~ ., data = shot_tags, family = "binomial")

summary(logistic)
