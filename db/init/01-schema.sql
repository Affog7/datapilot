-- =============================================================================
-- Schéma Olist (Brazilian E-Commerce Public Dataset)
-- Exécuté automatiquement par l'image postgres au premier démarrage
-- (volume pgdata vide) via /docker-entrypoint-initdb.d.
--
-- Règle : chaque table reprend les colonnes de son CSV DANS LE MÊME ORDRE,
-- pour que COPY ... FROM '/data/<fichier>.csv' fonctionne sans liste de colonnes.
--
-- Ordre de création = ordre de chargement (les parents avant les enfants,
-- à cause des clés étrangères).
-- =============================================================================

-- product_category_name_translation.csv
-- (le fichier commence par un BOM UTF-8 : sans effet, la ligne d'en-tête est ignorée par COPY ... HEADER)
CREATE TABLE product_category_name_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

-- olist_customers_dataset.csv
-- customer_id = client « par commande » ; customer_unique_id = vraie personne (non unique).
-- Les codes postaux gardent leurs zéros initiaux ("01037") : texte, pas entier.
CREATE TABLE customers (
    customer_id              VARCHAR(32) PRIMARY KEY,
    customer_unique_id       VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5)  NOT NULL,
    customer_city            TEXT        NOT NULL,
    customer_state           CHAR(2)     NOT NULL
);

-- olist_sellers_dataset.csv
CREATE TABLE sellers (
    seller_id              VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5)  NOT NULL,
    seller_city            TEXT        NOT NULL,
    seller_state           CHAR(2)     NOT NULL
);

-- olist_products_dataset.csv
-- « lenght » : faute de frappe d'origine, conservée volontairement.
-- Pas de FK vers product_category_name_translation : 2 catégories du CSV
-- (pc_gamer, portateis_cozinha_e_preparadores_de_alimentos) n'y figurent pas.
CREATE TABLE products (
    product_id                 VARCHAR(32) PRIMARY KEY,
    product_category_name      TEXT,
    product_name_lenght        INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           INTEGER,
    product_length_cm          INTEGER,
    product_height_cm          INTEGER,
    product_width_cm           INTEGER
);

-- olist_geolocation_dataset.csv
-- Plusieurs lignes par code postal (~1 M lignes, ~19 000 codes) : pas de clé primaire.
-- Pas de FK depuis customers/sellers : certains de leurs codes postaux sont absents ici.
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(5)       NOT NULL,
    geolocation_lat             DOUBLE PRECISION NOT NULL,
    geolocation_lng             DOUBLE PRECISION NOT NULL,
    geolocation_city            TEXT             NOT NULL,
    geolocation_state           CHAR(2)          NOT NULL
);

-- olist_orders_dataset.csv
-- Les dates d'étapes sont vides tant que l'étape n'a pas eu lieu (commandes annulées, en cours…).
-- CHECK : les 8 statuts présents dans le CSV. Un statut inconnu fait échouer le chargement.
CREATE TABLE orders (
    order_id                      VARCHAR(32) PRIMARY KEY,
    customer_id                   VARCHAR(32) NOT NULL REFERENCES customers (customer_id),
    order_status                  TEXT        NOT NULL CHECK (order_status IN (
                                      'created', 'approved', 'invoiced', 'processing',
                                      'shipped', 'delivered', 'canceled', 'unavailable')),
    order_purchase_timestamp      TIMESTAMP   NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP   NOT NULL
);

-- olist_order_items_dataset.csv
-- order_item_id = rang de l'article dans la commande (1, 2, 3…).
CREATE TABLE order_items (
    order_id            VARCHAR(32)   NOT NULL REFERENCES orders (order_id),
    order_item_id       INTEGER       NOT NULL,
    product_id          VARCHAR(32)   NOT NULL REFERENCES products (product_id),
    seller_id           VARCHAR(32)   NOT NULL REFERENCES sellers (seller_id),
    shipping_limit_date TIMESTAMP     NOT NULL,
    price               NUMERIC(10,2) NOT NULL,
    freight_value       NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- olist_order_payments_dataset.csv
-- Une commande peut être réglée en plusieurs paiements (payment_sequential).
-- CHECK : les 5 types présents dans le CSV (not_defined : 3 lignes, montant nul).
CREATE TABLE order_payments (
    order_id             VARCHAR(32)   NOT NULL REFERENCES orders (order_id),
    payment_sequential   INTEGER       NOT NULL,
    payment_type         TEXT          NOT NULL CHECK (payment_type IN (
                                           'credit_card', 'boleto', 'voucher',
                                           'debit_card', 'not_defined')),
    payment_installments INTEGER       NOT NULL,
    payment_value        NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- olist_order_reviews_dataset.csv
-- review_id n'est PAS unique (814 doublons) : clé primaire sur la paire (review_id, order_id).
-- Les commentaires peuvent contenir des retours à la ligne (champs entre guillemets).
CREATE TABLE order_reviews (
    review_id               VARCHAR(32) NOT NULL,
    order_id                VARCHAR(32) NOT NULL REFERENCES orders (order_id),
    review_score            SMALLINT    NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP   NOT NULL,
    review_answer_timestamp TIMESTAMP   NOT NULL,
    PRIMARY KEY (review_id, order_id)
);

-- -----------------------------------------------------------------------------
-- Index pour les jointures fréquentes (colonnes non couvertes par une clé primaire)
-- -----------------------------------------------------------------------------
CREATE INDEX idx_customers_unique_id     ON customers (customer_unique_id);
CREATE INDEX idx_products_category       ON products (product_category_name);
CREATE INDEX idx_geolocation_zip         ON geolocation (geolocation_zip_code_prefix);
CREATE INDEX idx_orders_customer_id      ON orders (customer_id);
CREATE INDEX idx_order_items_product_id  ON order_items (product_id);
CREATE INDEX idx_order_items_seller_id   ON order_items (seller_id);
CREATE INDEX idx_order_reviews_order_id  ON order_reviews (order_id);

-- Index pour les filtres par période (« ventes de 2017 », « par mois »…)
CREATE INDEX idx_orders_purchase_timestamp ON orders (order_purchase_timestamp);
