with matches as (
    select * from {{ ref('int_match_results') }}
),

-- Each match appears once, but each team plays once
-- We unpivot so every team gets a row per match
team_matches as (
    select
        match_id,
        season,
        match_date,
        venue,
        city,
        first_innings_team                              as team,
        'batting_first'                                 as match_role,
        winner,
        toss_winner,
        toss_decision,
        toss_winner_won_match,
        first_innings_runs                              as runs_scored,
        first_innings_wickets                           as wickets_lost,
        second_innings_runs                             as runs_conceded,
        first_innings_pp_runs                           as pp_runs,
        first_innings_sixes                             as sixes,
        first_innings_fours                             as fours,
        match_outcome_type,
        case when winner = first_innings_team 
             then 1 else 0 end                          as won
    from matches
    where first_innings_team is not null

    union all

    select
        match_id,
        season,
        match_date,
        venue,
        city,
        second_innings_team                             as team,
        'chasing'                                       as match_role,
        winner,
        toss_winner,
        toss_decision,
        toss_winner_won_match,
        second_innings_runs                             as runs_scored,
        second_innings_wickets                          as wickets_lost,
        first_innings_runs                              as runs_conceded,
        second_innings_pp_runs                          as pp_runs,
        second_innings_sixes                            as sixes,
        second_innings_fours                            as fours,
        match_outcome_type,
        case when winner = second_innings_team 
             then 1 else 0 end                          as won
    from matches
    where second_innings_team is not null
),

season_stats as (
    select
        team,
        season,

        -- Match counts
        count(*)                                        as matches_played,
        sum(won)                                        as matches_won,
        count(*) - sum(won)                             as matches_lost,

        -- Win rate
        round(sum(won) * 100.0 
            / nullif(count(*), 0), 1)                   as win_pct,

        -- Batting stats
        round(avg(runs_scored), 1)                      as avg_runs_scored,
        round(avg(runs_conceded), 1)                    as avg_runs_conceded,
        sum(sixes)                                      as total_sixes,
        sum(fours)                                      as total_fours,

        -- Toss stats
        count(case when toss_winner = team 
              then 1 end)                               as toss_wins,
        count(case when toss_winner = team 
              and won = 1 
              then 1 end)                               as toss_win_and_match_win,

        round(
            count(case when toss_winner = team 
                  and won = 1 then 1 end) * 100.0
            / nullif(count(case when toss_winner = team 
                          then 1 end), 0), 1)           as toss_win_conversion_pct,

        -- Batting first vs chasing
        count(case when match_role = 'batting_first' 
              then 1 end)                               as times_batted_first,
        count(case when match_role = 'chasing' 
              then 1 end)                               as times_chased,

        sum(case when match_role = 'batting_first' 
            then won else 0 end)                        as won_batting_first,
        sum(case when match_role = 'chasing' 
            then won else 0 end)                        as won_chasing,

        round(
            sum(case when match_role = 'batting_first' 
                then won else 0 end) * 100.0
            / nullif(count(case when match_role = 'batting_first' 
                          then 1 end), 0), 1)           as win_pct_batting_first,

        round(
            sum(case when match_role = 'chasing' 
                then won else 0 end) * 100.0
            / nullif(count(case when match_role = 'chasing' 
                          then 1 end), 0), 1)           as win_pct_chasing

    from team_matches
    group by team, season
)

select * from season_stats
order by season, win_pct desc