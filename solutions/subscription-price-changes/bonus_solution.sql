with subscription_price_changes as (

    select
        *
    from
        `advanced-sql-challenges`.`subscription_price_changes`.`subscription_price_changes`

),

rebillings as (

    select
        *
    from `advanced-sql-challenges`.`subscription_price_changes`.`rebillings`

),

subscription_price_changes_with_row_number as (

    select
        subscription_id,
        price,
        changed_at,
        row_number() over(
            partition by subscription_id
            order by changed_at desc
        ) as position
    from
        subscription_price_changes

),

last_subscription_change as (

    select



       subscription_id,
        price as new_price,
        changed_at
    from subscription_price_changes_with_row_number
    where position = 1

),

first_rebilling_date as (

    select
        subscription_id,
        min(rebilled_at) as effective_at
    from rebillings
    group by subscription_id

),

my_effective_subscription_changes as (

    select
        lsc.subscription_id,
        lsc.new_price,
        lsc.changed_at,
        frd.effective_at
    from last_subscription_change as lsc
    left join
        first_rebilling_date as frd on lsc.subscription_id = frd.subscription_id
    where frd.effective_at is not null
    order by
        subscription_id

),
og_effective_price_changes as (

    select * from `advanced-sql-challenges`.`subscription_price_changes`.`effective_subscription_changes`

)
(
  SELECT * FROM my_effective_subscription_changes
  EXCEPT DISTINCT
  SELECT * from og_effective_price_changes
)

UNION ALL

(
  SELECT * FROM og_effective_price_changes
  EXCEPT DISTINCT
  SELECT * from my_effective_subscription_changes
)
