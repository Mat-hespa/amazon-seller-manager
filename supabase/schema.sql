-- =====================================================
-- AMAZON SELLER MANAGER - DATABASE SCHEMA
-- =====================================================
-- Criado para: Supabase PostgreSQL
-- Versão: 1.0
-- =====================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABELAS
-- =====================================================

-- Tabela de perfis de usuário
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  seller_id TEXT UNIQUE,
  marketplace_id TEXT DEFAULT 'ATVPDKIKX0DER',
  marketplace_region TEXT DEFAULT 'us-east-1',
  refresh_token TEXT,
  company_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de pedidos (orders)
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  amazon_order_id TEXT UNIQUE NOT NULL,
  purchase_date TIMESTAMP WITH TIME ZONE,
  last_update_date TIMESTAMP WITH TIME ZONE,
  order_status TEXT,
  fulfillment_channel TEXT,
  sales_channel TEXT,
  order_channel TEXT,
  ship_service_level TEXT,
  order_total DECIMAL(12,2),
  currency_code TEXT DEFAULT 'USD',
  number_of_items_shipped INTEGER DEFAULT 0,
  number_of_items_unshipped INTEGER DEFAULT 0,
  payment_method TEXT,
  buyer_email TEXT,
  buyer_name TEXT,
  buyer_county TEXT,
  shipment_service_level_category TEXT,
  shipping_address JSONB,
  order_items JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de produtos
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  asin TEXT NOT NULL,
  sku TEXT NOT NULL,
  title TEXT,
  description TEXT,
  brand TEXT,
  price DECIMAL(10,2),
  cost DECIMAL(10,2),
  currency_code TEXT DEFAULT 'USD',
  quantity INTEGER DEFAULT 0,
  condition_type TEXT DEFAULT 'New',
  fulfillment_channel TEXT DEFAULT 'AFN',
  product_category TEXT,
  image_url TEXT,
  item_weight DECIMAL(10,2),
  package_dimensions JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, sku)
);

-- Tabela de inventário FBA
CREATE TABLE IF NOT EXISTS inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  sku TEXT NOT NULL,
  asin TEXT,
  fn_sku TEXT,
  product_name TEXT,
  quantity_available INTEGER DEFAULT 0,
  quantity_inbound_working INTEGER DEFAULT 0,
  quantity_inbound_shipped INTEGER DEFAULT 0,
  quantity_inbound_receiving INTEGER DEFAULT 0,
  quantity_reserved_fc_transfers INTEGER DEFAULT 0,
  quantity_reserved_fc_processing INTEGER DEFAULT 0,
  quantity_reserved_customer_orders INTEGER DEFAULT 0,
  quantity_unfulfillable INTEGER DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, sku)
);

-- Tabela de métricas diárias
CREATE TABLE IF NOT EXISTS daily_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  total_sales DECIMAL(12,2) DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  units_sold INTEGER DEFAULT 0,
  units_returned INTEGER DEFAULT 0,
  average_order_value DECIMAL(10,2) DEFAULT 0,
  total_fees DECIMAL(10,2) DEFAULT 0,
  total_costs DECIMAL(10,2) DEFAULT 0,
  net_profit DECIMAL(12,2) DEFAULT 0,
  conversion_rate DECIMAL(5,2) DEFAULT 0,
  sessions INTEGER DEFAULT 0,
  page_views INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, metric_date)
);

-- Tabela de alertas
CREATE TABLE IF NOT EXISTS alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL,
  severity TEXT DEFAULT 'info',
  title TEXT NOT NULL,
  message TEXT,
  related_sku TEXT,
  related_asin TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ÍNDICES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_date ON orders(purchase_date DESC);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);
CREATE INDEX IF NOT EXISTS idx_inventory_user_id ON inventory(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_user_date ON daily_metrics(user_id, metric_date DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_user_id ON alerts(user_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can manage own products" ON products FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own inventory" ON inventory FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own metrics" ON daily_metrics FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own alerts" ON alerts FOR ALL USING (auth.uid() = user_id);