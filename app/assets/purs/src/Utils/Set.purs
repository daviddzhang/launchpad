module Utils.Set
  ( toggle
  ) where

import Prelude

import Data.Set (Set, delete, insert, member)

toggle :: forall a. Ord a => a -> Set a -> Set a
toggle a set
  | a `member` set = delete a set
  | otherwise = insert a set
