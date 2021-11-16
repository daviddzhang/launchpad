-- A component for throttling messages. Useful for when you have messages which
-- are dispatched rapidly and trigger some non-trivial operation, like a window
-- resize event or a slider input.
-- Example Use:
--
--     data Message
--       = SliderChanged
--       | SetSliderValue Int
--       | ThrottleMsg (Throttle.Message Message)
--       | ...
--
--     type State =
--       { slider :: { value :: Int, throttle :: Throttle.State Message }
--       , ...
--       }
--
--     init = { slider: { value: 0, throttle: Throttle.init Milliseconds 100.0 }, ... }
--
--     update state (SetSliderValue value) = do
--       throttle ThrottleMsg SliderChanged
--       pure $ state { slider = state.slider { value = value } }
--     update state SliderChanged =
--       expensiveCalculation
--     update state (ThrottleMsg msg) =
--       Throttle.update ThrottleMsg (state { slider = state.slider { throttle = _ } }) state.slider msg
module Utils.Throttle
  ( init
  , throttle
  , update
  , module Utils.Throttle.State
  ) where

import Prelude

import Data.Time.Duration (Milliseconds)
import Effect.Aff (delay)
import Elmish (Transition, fork)
import Utils.Throttle.State (State, ThrottleState(..), Message(..))

init :: forall msg. Milliseconds -> State msg
init =
  { throttleState: Ready
  , delay: _
  }

-- | Call on receiving a `Throttle.Message`. Usually Elmish update functions only
-- require `State` and `Message` args and the `Bifunctor` instance is used to
-- transform them to the parent’s `State` and `Message`. This function accepts
-- functions for transforming the `State` and `Message` because it needs to
-- dispatch a message from the parent as well as its own.
update :: forall msg state
   . (Message msg -> msg)
  -> (State msg -> state)
  -> State msg
  -> Message msg
  -> Transition msg state
update parentMsg parentState state message =
  case state.throttleState, message of
    -- No request has been made yet to throttle a message. `Dispatch` the
    -- message after `delay`.
    Ready, Request msg -> do
      fork do
        delay state.delay
        pure $ parentMsg Dispatch
      pure $ parentState state { throttleState = Throttling msg }
    -- A message is currently waiting to be dispatched. Don't make a new
    -- `Request`, but update the message to be dispatched so that the latest
    -- version of the message gets dispatched at the end of the window.
    Throttling _, Request msg ->
      pure $ parentState state { throttleState = Throttling msg }
    -- A message is waiting to be dispatched and the time window is now up.
    -- Dispatch the message and reset the `throttleState`.
    Throttling msg, Dispatch -> do
      fork $ pure msg
      pure $ parentState state { throttleState = Ready }
    _, _ ->
      pure $ parentState state

-- | Call on the message you want to throttle. It will not be dispatched within
-- the `delay` window which was set up in `init`, but once at the end of that
-- window.
throttle :: forall msg. (Message msg -> msg) -> msg -> Transition msg Unit
throttle parentMsg msg =
  fork $ pure $ parentMsg $ Request msg
