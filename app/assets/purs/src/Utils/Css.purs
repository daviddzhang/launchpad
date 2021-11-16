-- | Some CSS values that we have to use with inline styles and cannot encode
-- | with CSS classes. Sometimes this happens.
--
-- ****************************************************************************
-- ********************************* STOP!!! **********************************
-- ****************************************************************************
--  Before adding a new value to this file, consider making it a class in
--  `app.scss` instead.
-- ****************************************************************************
-- ****************************************************************************
module Utils.Css
  ( zIndexTooltip
  ) where

zIndexTooltip = 1070 :: Int
