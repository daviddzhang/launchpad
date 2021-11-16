module Utils.NaturalOrder
  ( naturalOrderCompare
  ) where

import Prelude

import Data.CodePoint.Unicode as Char
import Data.Int as Int
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String.CodePoints as Str

-- | "Natural order" is alphabetical sorting, case-insentive, but also
-- | respecting numbers that may be infixed in the text. When two strings have
-- | the same prefix followed by several digits, this function will compare the
-- | numbers represented by those digits, and then continue comparing characters
-- | that follow the numbers (if any).
-- |
-- | For example:
-- |
-- |     "abc" < "bbc"
-- |     "abc1" < "abc2"
-- |     "abc01" < "abc2"
-- |     "abc12" > "abc5"
-- |     "abc002xyz" == "abc2xyz"
-- |     "abc002xyz" < "abc2yyz"
-- |     "abc003xyz" > "abc2yyz"
-- |
naturalOrderCompare :: String -> String -> Ordering
naturalOrderCompare a b = go 0 0
  where
    go idxA idxB = case Str.codePointAt idxA a, Str.codePointAt idxB b of
      Nothing, Nothing -> EQ
      Just _, Nothing -> GT
      Nothing, Just _ -> GT
      Just ca, Just cb | Char.isDecDigit ca && Char.isDecDigit cb ->
        compareNumbers idxA idxB
      Just ca, Just cb -> case compare (Char.toLower ca) (Char.toLower cb) of
        EQ -> go (idxA+1) (idxB+1)
        res -> res

    compareNumbers idxA idxB =
      case compare na.number nb.number of
        EQ -> go na.nextIndex nb.nextIndex
        res -> res
      where
        na = numberAt idxA a
        nb = numberAt idxB b

    numberAt idx str =
      { number: fromMaybe 0 $ Int.fromString numStr
      , nextIndex: idx + Str.length numStr
      }
      where
        numStr = str # Str.drop idx # Str.takeWhile Char.isDecDigit
