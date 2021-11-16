module Utils.Expandable
  ( State(..)
  , decode
  , encode
  , toggle
  ) where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Test.QuickCheck (class Arbitrary)
import Test.QuickCheck.Arbitrary (genericArbitrary)
import Utils.InverseLookup (allElements, inverseLookup)

data State
  = Expanded
  | Collapsed
derive instance Eq State
derive instance Generic State _
instance Arbitrary State where arbitrary = genericArbitrary

toggle :: State -> State
toggle = case _ of
  Expanded -> Collapsed
  Collapsed -> Expanded

encode :: State -> String
encode = case _ of
  Expanded -> "Expanded"
  Collapsed -> "Collapsed"

decode :: String -> Maybe State
decode =
  inverseLookup encode allElements
