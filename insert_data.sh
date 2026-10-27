#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

TEAM_VALUES=""
GAME_VALUES=""

while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  [[ "$year" == "year" ]] && continue

  for team in "$winner" "$opponent"
  do
    escaped_team=${team//\'/\'\'}
    TEAM_VALUES+="${TEAM_VALUES:+, }('$escaped_team')"
  done

  escaped_round=${round//\'/\'\'}
  escaped_winner=${winner//\'/\'\'}
  escaped_opponent=${opponent//\'/\'\'}

  GAME_VALUES+="${GAME_VALUES:+, }($year, '$escaped_round', '$escaped_winner', '$escaped_opponent', $winner_goals, $opponent_goals)"
done < games.csv

$PSQL "
INSERT INTO teams(name)
VALUES $TEAM_VALUES
ON CONFLICT (name) DO NOTHING;

INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT g.year, g.round, w.team_id, o.team_id, g.winner_goals, g.opponent_goals
FROM (VALUES $GAME_VALUES)
AS g(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams w ON w.name = g.winner
JOIN teams o ON o.name = g.opponent;
"
