module Test.Factory.Location
  ( address
  ) where

import Prelude

import Control.Monad.Gen (chooseInt)
import Data.Foldable (intercalate)
import RecordGen (genRecord)
import Test.Factory.Combinators (chooseFloat, elements')
import Test.Factory.Lorem as Lorem
import Test.QuickCheck.Gen (Gen, vectorOf)
import Utils.Address (RawAddress)
import Utils.Geo (allStates, stateName)

address :: Gen RawAddress
address = do
  genRecord
    { city: Lorem.properNoun
    , location:
        { lat: chooseFloat (-90.0) 90.0
        , lng: chooseFloat (-180.0) 180.0
        }
    , region: Lorem.properNoun
    , state: stateName <$> elements' allStates
    , street: Lorem.properNoun
    , zip: intercalate "" <$> vectorOf 5 (show <$> chooseInt 0 9)
    }
