module Utils.Quintile
  ( Quintile(..)
  , fromPercentile
  , genericName
  ) where

import Prelude

import Data.Generic.Rep (class Generic)

data Quintile
  = Q1
  | Q2
  | Q3
  | Q4
  | Q5
derive instance eqQuintile :: Eq Quintile
derive instance ordQuintile :: Ord Quintile
derive instance gQuintile :: Generic Quintile _

fromPercentile :: Number -> Quintile
fromPercentile n
  | n < 0.2 = Q1
  | n < 0.4 = Q2
  | n < 0.6 = Q3
  | n < 0.8 = Q4
  | otherwise = Q5

genericName :: Quintile -> String
genericName = case _ of
  Q1 -> "much lower than average"
  Q2 -> "lower than average"
  Q3 -> "about average"
  Q4 -> "above average"
  Q5 -> "among the highest"
