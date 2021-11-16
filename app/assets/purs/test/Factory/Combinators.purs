module Test.Factory.Combinators
  ( choose
  , chooseFloat
  , elementsWithDefault
  , elements'
  , nullable
  ) where

import Prelude

import Control.Monad.Gen (elements)
import Control.Monad.Gen as MG
import Data.Array.NonEmpty as NEA
import Data.Bounded.Generic (class GenericBottom, class GenericTop)
import Data.Enum.Generic (class GenericBoundedEnum)
import Data.Generic.Rep (class Generic)
import Data.Maybe (fromJust, fromMaybe)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Partial.Unsafe (unsafePartial)
import Test.QuickCheck.Gen (Gen)
import Utils.InverseLookup (allElements)

nullable :: forall a. Gen a -> Gen (Nullable a)
nullable gen =
  choose (Nullable.notNull <$> gen) (pure Nullable.null)

elementsWithDefault :: forall a rep. Generic a rep => GenericBoundedEnum rep => GenericTop rep => GenericBottom rep => a -> Gen a
elementsWithDefault a =
  allElements
    # NEA.fromArray
    # fromMaybe (NEA.singleton a)
    # elements

elements' :: forall a. Array a -> Gen a
elements' xs =
  elements $ unsafePartial $ fromJust $ NEA.fromArray xs

choose :: forall a. Gen a -> Gen a -> Gen a
choose =
  MG.choose

chooseFloat :: Number -> Number -> Gen Number
chooseFloat =
  MG.chooseFloat
