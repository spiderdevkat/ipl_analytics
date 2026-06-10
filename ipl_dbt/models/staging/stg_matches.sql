with source as (
    select * from {{ source('main', 'matches') }}
),

cleaned as (
    select
        id                                          as match_id,
        case
            when season = '2007/08' then '2008'
            when season = '2009/10' then '2010'
            when season = '2020/21' then '2021'
            else season
        end                                         as season,
        case nullif(city, 'NA')
            when 'Bengaluru' then 'Bangalore'
            else nullif(city, 'NA')
        end                                             as city,
        date                                        as match_date,
        match_type,
        case venue
            when 'Wankhede Stadium, Mumbai'
                then 'Wankhede Stadium'
            when 'Arun Jaitley Stadium, Delhi'
                then 'Arun Jaitley Stadium'
            when 'Feroz Shah Kotla'
                then 'Arun Jaitley Stadium'
            when 'Brabourne Stadium, Mumbai'
                then 'Brabourne Stadium'
            when 'Dr DY Patil Sports Academy, Mumbai'
                then 'Dr DY Patil Sports Academy'
            when 'Dubai International Cricket Stadium, Dubai'
                then 'Dubai International Cricket Stadium'
            when 'Eden Gardens'
                then 'Eden Gardens, Kolkata'
            when 'M Chinnaswamy Stadium, Bengaluru'
                then 'M Chinnaswamy Stadium'
            when 'M.Chinnaswamy Stadium'
                then 'M Chinnaswamy Stadium'
            when 'Maharashtra Cricket Association Stadium'
                then 'Maharashtra Cricket Association Stadium, Pune'
            when 'Rajiv Gandhi International Stadium, Uppal'
                then 'Rajiv Gandhi International Stadium'
            when 'MA Chidambaram Stadium, Chepauk'
                then 'MA Chidambaram Stadium'
            when 'MA Chidambaram Stadium, Chepauk, Chennai'
                then 'MA Chidambaram Stadium'
            when 'Punjab Cricket Association Stadium, Mohali'
                then 'Punjab Cricket Association Stadium'
            when 'Punjab Cricket Association IS Bindra Stadium, Mohali'
                then 'Punjab Cricket Association Stadium'
            when 'Punjab Cricket Association IS Bindra Stadium, Mohali, Chandigarh'
                then 'Punjab Cricket Association Stadium'
            when 'Punjab Cricket Association IS Bindra Stadium'
                then 'Punjab Cricket Association Stadium'
            when 'Sawai Mansingh Stadium'
                then 'Sawai Mansingh Stadium, Jaipur'
            when 'Sardar Patel Stadium, Motera'
                then 'Narendra Modi Stadium'
            when 'Narendra Modi Stadium, Ahmedabad'
                then 'Narendra Modi Stadium'
            when 'Rajiv Gandhi International Stadium, Uppal, Hyderabad'
                then 'Rajiv Gandhi International Stadium'
            else venue
        end                                             as venue,
        toss_decision,
        nullif(result, 'NA')                        as result,
        nullif(result_margin, 'NA')                 as result_margin,
        nullif(player_of_match, 'NA')               as player_of_match,
        nullif(method, 'NA')                        as method,
        super_over,

        -- Normalize team names
        case team1
            when 'Delhi Daredevils'             then 'Delhi Capitals'
            when 'Kings XI Punjab'              then 'Punjab Kings'
            when 'Royal Challengers Bangalore'  then 'Royal Challengers Bengaluru'
            when 'Deccan Chargers'              then 'Sunrisers Hyderabad'
            when 'Rising Pune Supergiant'       then 'Rising Pune Supergiants'
            else team1
        end                                         as team1,

        case team2
            when 'Delhi Daredevils'             then 'Delhi Capitals'
            when 'Kings XI Punjab'              then 'Punjab Kings'
            when 'Royal Challengers Bangalore'  then 'Royal Challengers Bengaluru'
            when 'Deccan Chargers'              then 'Sunrisers Hyderabad'
            when 'Rising Pune Supergiant'       then 'Rising Pune Supergiants'
            else team2
        end                                         as team2,

        case toss_winner
            when 'Delhi Daredevils'             then 'Delhi Capitals'
            when 'Kings XI Punjab'              then 'Punjab Kings'
            when 'Royal Challengers Bangalore'  then 'Royal Challengers Bengaluru'
            when 'Deccan Chargers'              then 'Sunrisers Hyderabad'
            when 'Rising Pune Supergiant'       then 'Rising Pune Supergiants'
            else toss_winner
        end                                         as toss_winner,

        case nullif(winner, 'NA')
            when 'Delhi Daredevils'             then 'Delhi Capitals'
            when 'Kings XI Punjab'              then 'Punjab Kings'
            when 'Royal Challengers Bangalore'  then 'Royal Challengers Bengaluru'
            when 'Deccan Chargers'              then 'Sunrisers Hyderabad'
            when 'Rising Pune Supergiant'       then 'Rising Pune Supergiants'
            else nullif(winner, 'NA')
        end                                         as winner

    from source
),

final as (
    select
        match_id,
        season,
        city,
        match_date,
        match_type,
        venue,
        team1,
        team2,
        toss_winner,
        toss_decision,
        winner,
        result,
        result_margin,
        player_of_match,
        method,
        super_over,
        case
            when toss_winner = team1 then team2
            else team1
        end                                         as toss_loser,
        case
            when toss_winner = winner then true
            else false
        end                                         as toss_winner_won_match
    from cleaned
)

select * from final