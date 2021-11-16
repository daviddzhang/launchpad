module Test.Factory
  ( factory
  ) where

import Prelude

import Effect.Class (class MonadEffect, liftEffect)
import Test.QuickCheck.Gen (Gen, randomSampleOne)

factory :: forall m a. MonadEffect m => Gen a -> m a
factory = liftEffect <<< randomSampleOne
