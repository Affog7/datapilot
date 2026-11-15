-- =============================================================================
-- Documentation du schéma, stockée dans la base (COMMENT ON).
-- Lue par l'agent via l'outil describe_table : chaque commentaire dit ce que
-- la donnée signifie et le piège à éviter.
-- Rejouable à volonté : COMMENT ON remplace le commentaire existant.
-- =============================================================================

-- customers
COMMENT ON TABLE customers IS
  'Un enregistrement par commande, pas par personne. Pour compter des personnes, utiliser customer_unique_id.';
COMMENT ON COLUMN customers.customer_id IS
  'Identifiant technique, différent à chaque commande. Ne jamais l''utiliser pour compter des clients ou des clients fidèles.';
COMMENT ON COLUMN customers.customer_unique_id IS
  'Identifiant de la personne. À utiliser pour compter les clients et les clients ayant commandé plusieurs fois.';

-- orders
COMMENT ON COLUMN orders.order_status IS
  'Statut de la commande. Valeurs : created, approved, invoiced, processing, shipped, delivered, canceled, unavailable. Une vente réalisée = delivered.';
COMMENT ON COLUMN orders.order_purchase_timestamp IS
  'Date et heure de la commande, en heure locale brésilienne, sans fuseau horaire.';
COMMENT ON COLUMN orders.order_delivered_customer_date IS
  'Date de livraison au client. Vide (NULL) si la commande n''est pas livrée.';
COMMENT ON COLUMN orders.order_estimated_delivery_date IS
  'Date de livraison promise au client. Une livraison est en retard si order_delivered_customer_date est postérieure.';

-- order_items
COMMENT ON TABLE order_items IS
  'Une ligne par article commandé. Une commande peut contenir plusieurs articles, de vendeurs différents.';
COMMENT ON COLUMN order_items.price IS
  'Prix d''un article, en réals brésiliens (BRL), hors frais de port.';
COMMENT ON COLUMN order_items.freight_value IS
  'Frais de port de cet article, en BRL. À exclure du chiffre d''affaires produit.';
COMMENT ON COLUMN order_items.shipping_limit_date IS
  'Date limite pour que le vendeur remette le colis au transporteur.';

-- order_payments
COMMENT ON TABLE order_payments IS
  'Paiements des commandes. Plusieurs lignes possibles par commande (ex. carte bancaire + bon d''achat).';
COMMENT ON COLUMN order_payments.payment_value IS
  'Montant payé en BRL, frais de port inclus. Ne pas l''additionner avec order_items.price (double comptage).';
COMMENT ON COLUMN order_payments.payment_installments IS
  'Nombre de mensualités choisies par le client (1 = paiement comptant).';

-- À TOI : écris ces deux commentaires
-- COMMENT ON COLUMN order_reviews.review_score IS '...';
-- COMMENT ON COLUMN products.product_category_name IS '...';