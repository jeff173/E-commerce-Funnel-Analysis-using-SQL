# User Funnel Analysis with SQL

## Project Objective

This project analyzes user behavior across an ecommerce funnel using MySQL. The goal is to measure how many users move through each step, identify where users drop off, compare conversion by traffic source, and find revenue opportunities.

Dataset used:

`C:\Users\Jeffrey\Downloads\user_events.csv`

## Dataset Columns

| Column | Meaning |
|---|---|
| `event_id` | Unique event record ID |
| `user_id` | Unique user ID |
| `event_type` | User action in the funnel |
| `event_date` | Timestamp of the event |
| `product_id` | Product connected to the event |
| `amount` | Purchase value, populated for purchases |
| `traffic_source` | Acquisition source |

## Funnel Steps

1. `page_view`
2. `add_to_cart`
3. `checkout_start`
4. `payment_info`
5. `purchase`

## Key Results

| Step | Users | Conversion from Previous Step | Conversion from Start |
|---|---:|---:|---:|
| Page View | 5,000 | 100.00% | 100.00% |
| Add to Cart | 1,553 | 31.06% | 31.06% |
| Checkout Start | 1,103 | 71.02% | 22.06% |
| Payment Info | 899 | 81.50% | 17.98% |
| Purchase | 826 | 91.88% | 16.52% |

Purchase summary:

| Metric | Value |
|---|---:|
| Purchase events | 826 |
| Total revenue | 87,975.11 |
| Average order value | 106.51 |

## Traffic Source Performance

| Traffic Source | Page View Users | Purchasers | Purchase Conversion |
|---|---:|---:|---:|
| Email | 522 | 177 | 33.91% |
| Paid Ads | 968 | 204 | 21.07% |
| Organic | 2,038 | 343 | 16.83% |
| Social | 1,472 | 102 | 6.93% |

## Business Insights

The biggest funnel drop happens between `page_view` and `add_to_cart`. Only 31.06% of users who view a page add an item to their cart, so product page quality, pricing clarity, product recommendations, and call-to-action placement are likely the highest-impact areas to improve.

Once users begin checkout, the funnel is comparatively strong. The conversion from `payment_info` to `purchase` is 91.88%, which suggests the final payment step is not the main problem.

Email is the strongest traffic source with a 33.91% purchase conversion rate. Social has the weakest conversion at 6.93%, so social traffic may need better targeting, landing pages, or campaign messaging.

## Strategic SQL Queries Included

The file `funnel_analysis.sql` includes:

- Data quality checks
- Event volume by funnel step
- Strict ordered user funnel
- Funnel performance by traffic source
- Product-level purchase and revenue analysis
- Average time from first page view to purchase

SQL dialect:

`MySQL 8+`

## Recommended Actions

1. Improve product-page conversion to increase `add_to_cart` users.
2. Study email campaigns and reuse the strongest messaging in other channels.
3. Audit social traffic landing pages because social brings many users but converts poorly.
4. Segment product performance by revenue and add-to-cart rate to identify products that attract interest but do not convert.
5. Monitor funnel metrics weekly after product-page or campaign changes.
