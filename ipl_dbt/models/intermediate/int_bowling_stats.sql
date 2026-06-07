with deliveries as (
    select * from {{ ref('stg_deliveries') }}
),

bowling as (
    select
        match_id,
        inning,
        bowling_team,
        bowler,

        -- Volume
        count(*)                                        as balls_bowled,
        -- Legal deliveries only (for over calculation)
        count(case when extras_type not in ('wides','noballs') 
              or extras_type is null 
              then 1 end)                               as legal_balls,
        sum(total_runs)                                 as runs_conceded,
        sum(is_wicket)                                  as wickets,

        -- Extras
        sum(case when extras_type = 'wides' 
            then 1 else 0 end)                          as wides,
        sum(case when extras_type = 'noballs' 
            then 1 else 0 end)                          as no_balls,

        -- Dot balls (bowler perspective)
        sum(case when total_runs = 0 
            then 1 else 0 end)                          as dot_balls,

        -- Phase-wise runs conceded
        sum(case when phase = 'Powerplay' 
            then total_runs else 0 end)                 as pp_runs_conceded,
        sum(case when phase = 'Middle' 
            then total_runs else 0 end)                 as middle_runs_conceded,
        sum(case when phase = 'Death' 
            then total_runs else 0 end)                 as death_runs_conceded,

        -- Phase-wise wickets
        sum(case when phase = 'Powerplay' 
            then is_wicket else 0 end)                  as pp_wickets,
        sum(case when phase = 'Death' 
            then is_wicket else 0 end)                  as death_wickets,

        -- Computed metrics
        round(
            count(case when extras_type not in ('wides','noballs')
                  or extras_type is null
                  then 1 end) / 6.0, 1)                as overs_bowled,

        round(
            sum(total_runs) * 6.0
            / nullif(
                count(case when extras_type not in ('wides','noballs')
                      or extras_type is null
                      then 1 end), 0), 2)               as economy_rate,

        round(
            count(case when extras_type not in ('wides','noballs')
                  or extras_type is null
                  then 1 end) * 1.0
            / nullif(sum(is_wicket), 0), 2)             as strike_rate,

        round(
            sum(case when total_runs = 0 then 1 else 0 end) * 100.0
            / nullif(count(*), 0), 2)                   as dot_ball_pct

    from deliveries
    where inning in (1, 2)
    group by match_id, inning, bowling_team, bowler
)

select * from bowling