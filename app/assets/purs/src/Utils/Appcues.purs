module Utils.Appcues
  ( show
  -- Flows
  , Flow
  , flowId
  , flowName
  , shortboardingFlow
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn2, runEffectFn2)

show :: Flow -> Effect Unit
show (Flow { id }) =
  runEffectFn2 show_ id onError
  where
    onError _message =
      -- TODO: Log error once APP-3884 is done
      pure unit

newtype Flow = Flow { id :: String, name :: String }

flowId :: Flow -> String
flowId (Flow { id }) = id

flowName :: Flow -> String
flowName (Flow { name }) = name

shortboardingFlow :: Flow
shortboardingFlow = Flow
  { id: "-MAlRX5ZTd37ud60ZDRX"
  , name: "Test 3 shortboarding"
  }

foreign import show_ :: EffectFn2 String (String -> Effect Unit) Unit
