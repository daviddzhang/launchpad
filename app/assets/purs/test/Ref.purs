-- | Reexports functions from `Effect.Ref`, but in polymorphic monad, so they
-- | don't have to be `liftEffect`ed every tme.
module Test.Ref
  ( new
  , read
  , write
  , module ReexportRef
  ) where

import Prelude

import Effect.Class (class MonadEffect, liftEffect)
import Effect.Ref (Ref) as ReexportRef
import Effect.Ref (Ref, new, read, write) as R

read :: forall m a. MonadEffect m => R.Ref a -> m a
read = liftEffect <<< R.read

write :: forall m a. MonadEffect m => a -> R.Ref a -> m Unit
write a = liftEffect <<< R.write a

new :: forall m a. MonadEffect m => a -> m (R.Ref a)
new = liftEffect <<< R.new
