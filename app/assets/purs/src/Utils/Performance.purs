-- | Wrapper around Web Performance API (`window.performance`).
module Utils.Performance
  ( mark
  , markStart
  , markEnd
  , markerStartTime
  -- Aff
  , markAff
  -- Tracking
  , trackTiming
  , measureAndTrack
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)

-- | Adds markers for how long it takes to compute `a` without introducing
-- | `Effect`. This is similar to how `Debug.Trace.trace` works.
foreign import mark :: forall a. String -> (Unit -> a) -> a

-- | Marks start of an operation.
foreign import markStart :: String -> Effect Unit

-- | Marks end of an operation.
foreign import markEnd :: String -> Effect Unit

-- | Marks duration of an asynchronous operation.
markAff :: forall m a. MonadAff m => String -> m a -> m a
markAff name action = do
  liftEffect $ markStart name
  result <- action
  liftEffect $ markEnd name
  pure result

-- | Measures the duration between `<marker>:start` and `<marker>:end` and
-- | reports to Google Analytics via user timing API.
measureAndTrack ::
  { marker :: String, category :: String, variable :: String } ->
  Effect Unit
measureAndTrack { marker, category, variable } = do
  value <- measureDuration marker
  trackTiming { category, variable, value }

foreign import trackTiming :: { category :: String, variable :: String, value :: Int } -> Effect Unit
foreign import measureDuration :: String -> Effect Int

---

markerStartTime :: String -> Effect (Maybe Number)
markerStartTime name = Nullable.toMaybe <$> markerStartTime_ name

foreign import markerStartTime_ :: String -> Effect (Nullable Number)
