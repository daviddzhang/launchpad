module Utils.Random
  ( oneOf
  , sampleOne
  , sampleOneOf
  , sampleNOf
  ) where

import Prelude

import Data.Array (length, take, (!!))
import Data.Maybe (Maybe)
import Random.LCG (Seed)
import Test.QuickCheck.Gen (Gen, Size, chooseInt, evalGen, shuffle)

-- | Samples a random generator given a seed. Like `randomSampleOne` but accepts
-- | a `Seed` argument.
sampleOne :: forall a. Seed -> Gen a -> a
sampleOne seed gen = evalGen gen { newSeed: seed, size: 10 }

sampleOneOf :: forall a. Seed -> Array a -> Maybe a
sampleOneOf seed xs = sampleOne seed $ oneOf xs

sampleNOf :: forall a. Seed -> Size -> Array a -> Array a
sampleNOf seed size xs = (take size <$> shuffle xs) `evalGen` { newSeed: seed, size }

-- | Create a random generator which selects a value from an array with uniform
-- | probability.
oneOf :: forall a. Array a -> Gen (Maybe a)
oneOf xs = do
  n <- chooseInt zero (length xs - one)
  pure $ xs !! n



--foreign import sampleNOf :: Array
