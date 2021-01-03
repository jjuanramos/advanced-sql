# Notes

## Development

As the complexity of this exercise increased in comparison with the first one, I have decided to replicate the workflow I follow when working at similar projects in homyspace. A tl;dr of this workflow would be:

1. I define the acceptance criteria by which the exercise would be considered as complete. In this case, the AC is to obtain the same results as the official BigQuery apportioning-payments table.
2. Before starting the development process, I use Lucidchart to do a poc of how the DAG that created the final table or view will look like. At work, I I compare it to the current full DAG of the project, in order to keep everything as DRY as possible (such as limiting the number of joins) in order to keep the project as performant and maintainable as it can get. A related video for this topic would be [this cool video from Coalesce 2020](https://www.youtube.com/watch?v=5W6VrnHVkCA).


For this exercise, the DAG looks like this:

![](images/advanced-sql.png)

At homyspace, the data modelling process is divided in different stages:
src --> base (optional) --> stg --> int (optional) --> dim (optional) --> fact --> obt.

On the same note, every model would actually be a model in dbt. Here, due to the nature of the exercise, every model is actually a CTE.

For this project, we jumped directly from intermediate to fact. We could have created two dimension tables, *dim_payout_amount* and *dim_refund_amount*, and then have left joined them with the staging model of inbound payments. We decided to not do so in order to keep it DRY, so instead we created intermediate models that host the transformations needed to obtain those dimensions + the columns of the inbound payments table.

## Assumptions about the data

1. Payment id is the primary key, and as such is unique and not null.
2. Every task id has a payment id associated.
3. There is one payout and one refund payment maximum per task.
4. Nulls are not wanted, and 0 is preferred.
5. We pay as much as we can from an inbound payment to every payout payment, before going to next payout payment. The same for refund payments.
6. Payout payments have preference over refund payments. I.e. if an inbound payment is 20u, and we have a payout payment of 20u and a refund payment of 1u, we will prioritize the payout payment and leave the refund payment for the next inbound payment (payment payment payment payment).

