module Utils.Text
  ( enumerateWithOr
  , enumerateWithAnd
  , Conjunction
  ) where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Data.Array.NonEmpty as NEA
import Data.Foldable (intercalate)


data Conjunction = And | Or

enumerateWithOr :: NonEmptyArray String -> String
enumerateWithOr = enumerateWith Or

enumerateWithAnd :: NonEmptyArray String -> String
enumerateWithAnd = enumerateWith And

enumerateWith :: Conjunction -> NonEmptyArray String -> String
enumerateWith conjunction terms =
    case NEA.unsnoc terms of
      { init: [], last } -> last
      { init: [term], last } -> term <> " " <> conjunctionStr <> " " <> last
      -- Oxford comma FTW!
      { init, last } -> intercalate ", " init <> ", " <> conjunctionStr <> " " <> last
    where
      conjunctionStr = case conjunction of
        And -> "and"
        Or -> "or"
