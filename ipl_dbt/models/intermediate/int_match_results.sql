with matches as (
    select * from {{ ref('stg_matches') }}
),

deliveries as (
    select * from {{ ref('stg_deliveries') }}
),

-- Aggregate runs per innings per match
innings_totals as (
    select
        match_id,
        inning,
        batting_team_clean as batting_team,
        bowling_team_clean as bowling_team,
        sum(total_runs)                                 as innings_runs,
        sum(is_wicket)                                  as innings_wickets,
        count(*)                                        as balls_bowled,
        sum(is_four)                                    as fours,
        sum(is_six)                                     as sixes,
        sum(is_dot_ball)                                as dot_balls,

        -- Phase-wise runs
        sum(case when phase = 'Powerplay' 
            then total_runs else 0 end)                 as pp_runs,
        sum(case when phase = 'Middle' 
            then total_runs else 0 end)                 as middle_runs,
        sum(case when phase = 'Death' 
            then total_runs else 0 end)                 as death_runs,

        round(sum(total_runs) * 6.0 
            / nullif(count(*), 0), 2)                   as run_rate

    from deliveries
    where inning in (1, 2)
    group by match_id, inning, batting_team_clean, bowling_team_clean
),

-- Separate 1st and 2nd innings
first_innings as (
    select * from innings_totals where inning = 1
),

second_innings as (
    select * from innings_totals where inning = 2
),

-- Join everything together
final as (
    select
        m.match_id,
        m.season,
        m.match_date,
        m.venue,
        m.city,
        m.team1,
        m.team2,
        m.toss_winner,
        m.toss_decision,
        m.toss_winner_won_match,
        m.winner,
        m.result,
        m.result_margin,
        m.player_of_match,
        m.method,

        -- First innings
        f.batting_team                                  as first_innings_team,
        f.innings_runs                                  as first_innings_runs,
        f.innings_wickets                               as first_innings_wickets,
        f.pp_runs                                       as first_innings_pp_runs,
        f.middle_runs                                   as first_innings_middle_runs,
        f.death_runs                                    as first_innings_death_runs,
        f.fours                                         as first_innings_fours,
        f.sixes                                         as first_innings_sixes,
        f.run_rate                                      as first_innings_run_rate,

        -- Second innings
        s.batting_team                                  as second_innings_team,
        s.innings_runs                                  as second_innings_runs,
        s.innings_wickets                               as second_innings_wickets,
        s.pp_runs                                       as second_innings_pp_runs,
        s.middle_runs                                   as second_innings_middle_runs,
        s.death_runs                                    as second_innings_death_runs,
        s.fours                                         as second_innings_fours,
        s.sixes                                         as second_innings_sixes,
        s.run_rate                                      as second_innings_run_rate,

        -- Chase context
        f.innings_runs                                  as target_runs,
        (f.innings_runs - s.innings_runs)               as runs_deficit,

        case
            when m.winner = s.batting_team then true
            else false
        end                                             as chase_successful,

        case
            when m.winner = f.batting_team then 'defended'
            when m.winner = s.batting_team then 'chased'
            else 'no result'
        end                                             as match_outcome_type

    from matches m
    left join first_innings f  on m.match_id = f.match_id
    left join second_innings s on m.match_id = s.match_id
)

select * from final