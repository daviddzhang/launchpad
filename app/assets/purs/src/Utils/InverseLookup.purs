module Utils.InverseLookup
  ( inverseLookup
  , allElements
  ) where

import Prelude

import Data.Array (mapMaybe, (..))
import Data.Generic.Rep (class Generic)
import Data.Bounded.Generic (class GenericBottom, class GenericTop)
import Data.Bounded.Generic (genericBottom, genericTop) as G
import Data.Enum.Generic (class GenericBoundedEnum)
import Data.Enum.Generic (genericFromEnum, genericToEnum) as G
import Data.Maybe (Maybe)
import Data.Tuple (Tuple(..))
import Foreign.Object as FO

-- | From an array of things and an injective function `thing -> String`,
-- | creates a reverse lookup function mapping back from `String` to `Maybe
-- | thing`, in O(1) time complexity, utilizing a JS hash.
inverseLookup :: forall a. (a -> String) -> Array a -> (String -> Maybe a)
inverseLookup itemKey items = \s -> FO.lookup s hash
  where
    hash = items <#> (\f -> Tuple (itemKey f) f) # FO.fromFoldable

allElements ::
  forall a rep.
  Generic a rep =>
  GenericBoundedEnum rep =>
  GenericTop rep =>
  GenericBottom rep =>
  Array a
allElements = mapMaybe G.genericToEnum (idxFrom..idxTo)
  where
    idxFrom = G.genericFromEnum (G.genericBottom :: a)
    idxTo = G.genericFromEnum (G.genericTop :: a)
