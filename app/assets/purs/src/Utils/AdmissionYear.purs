module Utils.AdmissionYear
  ( AdmissionYear(..)
  , parse
  ) where

import Prelude

import Data.Maybe (Maybe(..))

data AdmissionYear
  = Freshman
  | Sophomore
  | Junior
  | Senior
derive instance eqAdmissionYear :: Eq AdmissionYear

parse :: String -> Maybe AdmissionYear
parse = case _ of
  "freshman" -> Just Freshman
  "sophomore" -> Just Sophomore
  "junior" -> Just Junior
  "senior" -> Just Senior
  _ -> Nothing
