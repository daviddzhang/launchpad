module Utils.Address
  ( Address
  , RawAddress
  , format
  , cityState
  , parse
  ) where

import Prelude

import Data.Foldable (intercalate)
import GeoJSON.Types.Coordinate as Coordinate
import Utils.Geo as USState

type RawAddress =
  { street :: String
  , city :: String
  , state :: String
  , region :: String
  , zip :: String
  , location :: { lat :: Number, lng :: Number }
  }

type Address =
  { street :: String
  , city :: String
  , state :: USState.USState
  , region :: String
  , zip :: String
  , location :: Coordinate.Coordinate
  }

parse :: RawAddress -> Address
parse raw = raw
  { state = USState.stateFromName raw.state
  , location = Coordinate.fromLatLng raw.location
  }

cityState :: Address -> String
cityState a = a.city <> ", " <> USState.stateName a.state

format :: Address -> String
format a =
  intercalate " " [a.street, cityState a, a.zip]
