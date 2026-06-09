with bowling as (
    select * from {{ ref('int_bowling_stats') }}
),

matches as (
    select * from {{ ref('stg_matches') }}
),

bowling_with_meta as (
    select
        b.*,
        m.season,
        m.match_date,
        m.venue,
        m.city
    from bowling b
    left join matches m on b.match_id = m.match_id
),

season_stats as (
    select
        bowler                                          as player_name,
        season,
        bowling_team                                    as team,

        -- Volume
        count(*)                                        as matches,
        sum(legal_balls)                                as total_legal_balls,
        round(sum(legal_balls) / 6.0, 1)               as total_overs,
        sum(runs_conceded)                              as total_runs_conceded,
        sum(wickets)                                    as total_wickets,

        -- Extras
        sum(wides)                                      as total_wides,
        sum(no_balls)                                   as total_no_balls,
        sum(dot_balls)                                  as total_dot_balls,

        -- Milestones
        count(case when wickets >= 5 
              then 1 end)                               as five_wicket_hauls,
        count(case when wickets >= 3 
              then 1 end)                               as three_plus_wickets,
        max(wickets)                                    as best_bowling_wickets,

        -- Phase wickets
        sum(pp_wickets)                                 as total_pp_wickets,
        sum(death_wickets)                              as total_death_wickets,

        -- Phase runs conceded
        sum(pp_runs_conceded)                           as total_pp_runs_conceded,
        sum(middle_runs_conceded)                       as total_middle_runs_conceded,
        sum(death_runs_conceded)                        as total_death_runs_conceded,
        
        -- Computed metrics
        {{ economy_rate('sum(runs_conceded)', 'sum(legal_balls)') }}
                                                        as season_economy,

        {{ dot_ball_pct('sum(dot_balls)', 'sum(balls_bowled)') }}
                                                        as season_dot_pct,

        -- Bowling average
        round(
            sum(runs_conceded) * 1.0
            / nullif(sum(wickets), 0), 2)               as bowling_average,

        -- Bowling strike rate
        round(
            sum(legal_balls) * 1.0
            / nullif(sum(wickets), 0), 2)               as bowling_strike_rate

    from bowling_with_meta
    group by bowler, season, bowling_team
)

select * from season_stats
order by season, total_wickets desc