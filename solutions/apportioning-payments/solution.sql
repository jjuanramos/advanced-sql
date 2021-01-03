with base_payments as (

    select * from `advanced-sql-challenges`.`apportioning_payments`.`payments`

),

stg_inbound_payments as (

    select *
    from base_payments
    where payment_type = 'inbound'

),

stg_payout_payments as (

    select *
    from base_payments
    where payment_type = 'payout'

),

stg_refund_payments as (

    select *
    from base_payments
    where payment_type = 'refund'

),

int_inbound_payout_payments as (

    select
        inbound.task_id,
        inbound.payment_id,
        inbound.amount as inbound_amount,
        payout.amount as og_payout_amount,
        (
            payout.amount - lag(
                inbound.amount
            ) over(partition by inbound.task_id order by inbound.payment_id)
        ) as left_to_pay
    from
        stg_inbound_payments as inbound
    left join stg_payout_payments as payout on payout.task_id = inbound.task_id

),

int_includes_dim_payout_amount as (

    select
        task_id,
        payment_id,
        inbound_amount,
        case
            when
                og_payout_amount is null then 0
            when
                left_to_pay is null then (
                    case
                        when
                            og_payout_amount > inbound_amount then inbound_amount
                        else og_payout_amount
                    end
                )
            when
                left_to_pay < 0 then 0
            else left_to_pay end as payout_amount
    from
        int_inbound_payout_payments

),

int_inbound_refund_payments as (

    select
        main_table.task_id,
        main_table.payment_id,
        main_table.inbound_amount,
        main_table.payout_amount,
        refund.amount as og_refund_amount,
        main_table.inbound_amount - main_table.payout_amount as available_for_refund,
        (refund.amount - lag(
                main_table.inbound_amount - main_table.payout_amount
            ) over(
                partition by main_table.task_id order by main_table.payment_id
            )
        ) as left_to_pay
    from int_includes_dim_payout_amount as main_table
    left join
        stg_refund_payments as refund on refund.task_id = main_table.task_id

),

fct_inbound_payment_states as (
    select
        task_id,
        payment_id as inbound_payment_id,
        inbound_amount,
        payout_amount,
        case
            when
                og_refund_amount is null then 0
            when
                left_to_pay is null then (
                    case
                        when
                            og_refund_amount > available_for_refund then available_for_refund
                        else og_refund_amount
                    end
                )
            when
                left_to_pay < 0 then 0
            when 
                left_to_pay > available_for_refund then available_for_refund
            else left_to_pay end as refund_amount
    from
        int_inbound_refund_payments
    order by
        task_id, inbound_payment_id
)

select *
from fct_inbound_payment_states

