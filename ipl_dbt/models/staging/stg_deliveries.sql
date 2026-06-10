with source as (
    select * from {{ source('main', 'deliveries') }}
),

cleaned as (
    select
        match_id,
        inning,
        batting_team,
        bowling_team,
        -- Fix 0-based over to 1-based
        over + 1                                    as over_number,
        ball                                        as ball_number,
        batter,
        bowler,
        non_striker,
        batsman_runs,
        extra_runs,
        total_runs,
        nullif(extras_type, '')                     as extras_type,
        is_wicket,
        -- Clean 'NA' strings to proper nulls
        nullif(player_dismissed, 'NA')              as player_dismissed,
        nullif(dismissal_kind, 'NA')                as dismissal_kind,
        nullif(fielder, 'NA')                       as fielder,

        -- Normalize team names
        case batting_team
            when 'Delhi Daredevils'           then 'Delhi Capitals'
            when 'Kings XI Punjab'            then 'Punjab Kings'
            when 'Royal Challengers Bangalore' then 'Royal Challengers Bengaluru'
            when 'Deccan Chargers'            then 'Sunrisers Hyderabad'
            when 'Rising Pune Supergiant'     then 'Rising Pune Supergiants'
            else batting_team
        end                                         as batting_team_clean,

        case bowling_team
            when 'Delhi Daredevils'           then 'Delhi Capitals'
            when 'Kings XI Punjab'            then 'Punjab Kings'
            when 'Royal Challengers Bangalore' then 'Royal Challengers Bengaluru'
            when 'Deccan Chargers'            then 'Sunrisers Hyderabad'
            when 'Rising Pune Supergiant'     then 'Rising Pune Supergiants'
            else bowling_team
        end                                         as bowling_team_clean,
        -- Derived columns
        case when batsman_runs = 4 then 1 else 0 end  as is_four,
        case when batsman_runs = 6 then 1 else 0 end  as is_six,
        case when batsman_runs = 0 
             and extra_runs = 0 then 1 else 0 end     as is_dot_ball,
        -- Phase of play
        case
            when (over + 1) between 1 and 6   then 'Powerplay'
            when (over + 1) between 7 and 15  then 'Middle'
            when (over + 1) between 16 and 20 then 'Death'
        end                                           as phase
    from source
)

select * from cleaned