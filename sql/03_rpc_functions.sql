-- sql/03_rpc_functions.sql
-- Adds inventory, incrementing quantity when the same item already exists.

CREATE OR REPLACE FUNCTION public.upsert_inventory_item(
  p_printing_code TEXT,
  p_rarity        TEXT,
  p_edition       TEXT DEFAULT '',
  p_card_grade    TEXT DEFAULT 'Ungraded',
  p_location      TEXT DEFAULT NULL,
  p_quantity      INT  DEFAULT 1,
  p_price_each    NUMERIC DEFAULT NULL,
  p_variant_name  TEXT DEFAULT ''
)
RETURNS TABLE (
  inventory_id BIGINT,
  printing_id  BIGINT,
  new_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_printing_id BIGINT;
BEGIN
  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'Quantity must be a positive integer';
  END IF;

  -- Find the printing
  SELECT pr.printing_id
  INTO v_printing_id
  FROM public.printings pr
  WHERE pr.printing_code = UPPER(TRIM(p_printing_code))
    AND pr.rarity = TRIM(p_rarity)
    AND pr.variant_name = COALESCE(NULLIF(TRIM(p_variant_name), ''), '')
  LIMIT 1;

  IF v_printing_id IS NULL THEN
    RAISE EXCEPTION 'Printing not found for code=% rarity=% variant=%',
      p_printing_code, p_rarity, COALESCE(NULLIF(p_variant_name,''), '');
  END IF;

  -- Ensure the unique key exists (safe to run repeatedly)
  -- You can remove this block after you've added the constraint permanently.
  BEGIN
    ALTER TABLE public.inventory
      ADD CONSTRAINT inventory_identity_key
      UNIQUE (printing_id, card_grade, edition, location);
  EXCEPTION WHEN duplicate_object THEN
    -- constraint already exists
    NULL;
  END;

  -- Upsert: increment quantity if exists
  INSERT INTO public.inventory (
    printing_id,
    card_grade,
    edition,
    location,
    quantity,
    price_each,
    binder_value
  )
  VALUES (
    v_printing_id,
    COALESCE(NULLIF(TRIM(p_card_grade), ''), 'Ungraded'),
    COALESCE(TRIM(p_edition), ''),
    p_location,
    p_quantity,
    p_price_each,
    -- if price_each provided, compute binder_value for this insert;
    -- if null, leave binder_value null (or 0) and you can update later
    CASE
      WHEN p_price_each IS NULL THEN NULL
      ELSE ROUND((p_price_each * p_quantity)::numeric, 2)
    END
  )
  ON CONFLICT (printing_id, card_grade, edition, location)
  DO UPDATE SET
    quantity = public.inventory.quantity + EXCLUDED.quantity,
    price_each = COALESCE(EXCLUDED.price_each, public.inventory.price_each),
    binder_value = CASE
      WHEN COALESCE(EXCLUDED.price_each, public.inventory.price_each) IS NULL THEN public.inventory.binder_value
      ELSE ROUND(
        (COALESCE(EXCLUDED.price_each, public.inventory.price_each)
         * (public.inventory.quantity + EXCLUDED.quantity))::numeric,
        2
      )
    END
  RETURNING public.inventory.inventory_id,
            public.inventory.printing_id,
            public.inventory.quantity
  INTO inventory_id, printing_id, new_quantity;

  RETURN NEXT;
END;
$$;
