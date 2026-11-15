-- =============================================================================
-- Chargement des CSV Olist (montés en lecture seule dans /data par docker-compose).
-- Même ordre que 01-schema.sql : les parents avant les enfants (clés étrangères).
-- =============================================================================

COPY product_category_name_translation FROM '/data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);
COPY customers FROM '/data/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY sellers FROM '/data/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY products FROM '/data/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY geolocation FROM '/data/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY orders FROM '/data/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY order_items FROM '/data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY order_payments FROM '/data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY order_reviews FROM '/data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true);
