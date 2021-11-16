module Test.Utils.API
  ( mockApi
  ) where

import Prelude

import Effect.Class (class MonadEffect, liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)
import Test.Cleanup (class MonadCleanup, CleanupT, cleanupAction)

mockApi :: forall api m. MonadEffect m => MonadCleanup m => api -> api -> CleanupT m Unit
mockApi api fn = do
  mock api fn
  cleanupAction $ unmock api

-- | Takes an API function (the result of calling `apiEndpoint`) and a mock
-- | function that should be used instead and adds that to the mock dictionary
-- | to be used whenever that API is called.
-- |
-- | The downside of this API is that we have to call it for every API that gets
-- | called in a test. We can’t just default every API to do nothing and only
-- | mock when we need to. It’s unclear how to do that, though, as PureScript
-- | uses a third party XHR library which can’t easily be monkey patched.
-- |
-- | Another solution might be to use a generic monad for `apiEndpoint`’s return
-- | type, but that would be a huge change requiring adding constraints all over
-- | the codebase.
-- |
-- | NOTE: This is internal. Use `mockApi` instead.
mock :: forall m a. MonadEffect m => a -> a -> m Unit
mock api fn = liftEffect $ runEffectFn2 mock_ api fn

-- | Removes an API function from the mock dictionary.
-- |
-- | NOTE: This is internal. Use `mockApi` instead.
unmock :: forall m a. MonadEffect m => a -> m Unit
unmock = liftEffect <<< runEffectFn1 unmock_

foreign import mock_ :: forall a. EffectFn2 a a Unit
foreign import unmock_ :: forall a. EffectFn1 a Unit
