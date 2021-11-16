module Utils.Loadable
  ( Loadable(..)
  , mapMaybe
  , toMaybe
  , toPending
  ) where

import Prelude

import Data.Maybe (Maybe(..))

-- | Represents a value that may undergo cycles of loading/reloading (or
-- | computing/recomputing), such as stuff we load/reload from the server in
-- | response to user actions.
data Loadable a
  = Absent
  -- ^ The value is not there and never was.
  | Present a
  -- ^ We have the value right here, available for use.
  | Pending (Maybe a)
  -- ^ We're currently loading or reloading the value (e.g. from the server),
  -- and we may or may not have a "previous" version of the value, from before
  -- we started reloading.

derive instance Functor Loadable

toMaybe :: ∀ a. Loadable a -> Maybe a
toMaybe = case _ of
  Absent -> Nothing
  Present a -> Just a
  Pending a -> a

mapMaybe :: ∀ a b. (a -> Maybe b) -> Loadable a -> Loadable b
mapMaybe f = case _ of
  Pending Nothing -> Pending Nothing
  Pending (Just a) | Just b <- f a -> Pending (Just b)
  Present a | Just b <- f a -> Present b
  _ -> Absent

-- | Transition a value to the "pending" state, keeping a previous version of it
-- | if present.
toPending :: ∀ a. Loadable a -> Loadable a
toPending = case _ of
  Absent -> Pending Nothing
  Present a -> Pending (Just a)
  Pending a -> Pending a
