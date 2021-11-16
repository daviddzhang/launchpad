module Utils.Array
  ( chunks
  , chunksOf
  , modifyWhere
  , updateWhere
  , modifyFirst
  ) where

import Prelude

import Data.Array (drop, length, take, uncons, (:))
import Data.Int (ceil, toNumber)
import Data.Maybe (fromMaybe)

-- | Splits an array into `n` groups where the last group is the same size or
-- smaller than the rest, which should all be equally sized
chunks :: forall a. Int -> Array a -> Array (Array a)
chunks n xs =
  chunksOf (ceil (toNumber (length xs) / toNumber n)) xs

-- | Splits an array into groups of `size` where the last group is the same or
-- smaller than `size`
chunksOf :: forall a. Int -> Array a -> Array (Array a)
chunksOf size = case _ of
  [] -> []
  xs' -> take size xs' : chunksOf size (drop size xs')

updateWhere :: forall a. (a -> Boolean) -> a -> Array a -> Array a
updateWhere p y =
  modifyWhere p (const y)

modifyWhere :: forall a. (a -> Boolean) -> (a -> a) -> Array a -> Array a
modifyWhere p f xs =
  xs <#> \x -> if p x then f x else x

-- Modify the first matching element in an array
-- ie. `modifyFirst (_ % 2 == 0) (_ + 1) [1,2,3,4] == [1,3,3,4]`
modifyFirst :: forall a. (a -> Boolean) -> (a -> a) -> Array a -> Array a
modifyFirst p f xs = fromMaybe xs do
  { head, tail } <- uncons xs
  if p head
  then
    pure $ f head : tail
  else
    pure $ head : modifyFirst p f tail
