Understanding expected goals (xG)
========================================================
author: Izan Ahmed and Priyank Shah
date: 
autosize: true

Introduction
========================================================

- Expected goals is a measure of the quality of a shot.
- xG values range from 0 to 1, where an xG of 1.0 would indicate a 100% probability of a goal.  
- Using predictive modeling we assessed the goal-scoring probability in a soccer match and calculated the likelihood of the goal being scored.

![an image caption: sample](goals1.png) (xG of this goal is given as 0.0006)

Dataset
========================================================

- The dataset was provided by Wyscout. 
- It contains all spatio-temporal events that occur in each match for all matches in 7 different competitions: La Liga, Serie A, Bundesliga, Premier League, Ligue 1, FIFA World Cup 2018, UEFA Euro Cup 2016.
- A single match event contains information about the type of event, position, time, outcome, player and other characteristics.

![an image caption: Initial Dataset](firstpic.JPG)

Methods of Collection
========================================================

- As we are only interested in shooting events, we decided to select the following variables from the dataset to predict the probability of a goal:
- 1. Distance to the goal center
- 2. The angle to goal 
- 3. The binary variable as to whether or not it was a counter attack
- 4. The binary variable as to whether or not it was from the dominant foot of the player.

![an image caption: Initial Dataset](firstpic.JPG)

Analytic Methods
========================================================

- We decided to fit 3 logistic regression models with the binary variable for goal or not as the response all of them trained on the Premier League dataset (highest number of observations). 
- Our first model includes the distance, and the angle to goal as the explanatory variables.
- The second model includes the 2 primary explanatory variables along with another binary variable for counter attack or not. 
- The third and final model contains the previous 3 variables along with another binary variable, shot taken from the dominant foot or not.

- Moreover, we wanted to test the significance of the variables in our model so we added irrelevant variables, such as time to our model.
- Later on, we assessed the interactions of the variables based on the summary of the regression and statistically significant p-values.
- To further solidify the results, we performed the drop in deviance test to compare each model with others.
- Lastly, we took our best model and compared the predicted goals vs actual goals scored in 3 other large datasets.


Results
========================================================

Discussion
========================================================


