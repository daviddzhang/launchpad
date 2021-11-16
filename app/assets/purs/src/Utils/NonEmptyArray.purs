module Utils.NonEmptyArray
  ( maximumWith
  , minimumWith
  ) where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Data.Function (on)
import Data.Semigroup.Foldable (maximumBy, minimumBy)

maximumWith :: forall a b. Ord b => (a -> b) -> NonEmptyArray a -> a
maximumWith fn = maximumBy (compare `on` fn)

minimumWith :: forall a b. Ord b => (a -> b) -> NonEmptyArray a -> a
minimumWith fn = minimumBy (compare `on` fn)
