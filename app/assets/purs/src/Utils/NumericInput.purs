module Utils.NumericInput
  ( numericInput
  ) where

import Prelude

import Data.Int as Int
import Data.Maybe (Maybe(..))
import Effect.Class (liftEffect)
import Elmish (Dispatch, ReactElement, ComponentDef, forkVoid, (<?|))
import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Elmish.HTML.Styled as H
import Utils.HTML (eventTargetValue)

type Args =
  { className :: String
  , min :: Int
  , max :: Int
  , step :: Int
  , value :: Int
  , onChange :: Dispatch Int
  }

-- | A regular textbox for editing numbers that works around the issue of
-- | backspacing: in a plain numeric textbox that is hooked up to an `Int` field
-- | via `onChange`, it's impossible to backspace the whole text, because empty
-- | text is technically not a number, so the event handler doesn't fire, and
-- | the numeric field doesn't change, creating a user-facing effect of
-- | "backspace not working". This component solves the issue by keeping the
-- | current value as a text field, and only reporting changes back to the
-- | consumer when the text actually represents a number.
numericInput :: Args -> ReactElement
numericInput = wrapWithLocalState (ComponentName "NumericInput") def

type Message = String

type State =
  { textValue :: String
  , lastKnownValue :: Int
  }

def :: Args -> ComponentDef Message State
def args = { init, view, update }
  where
    init = pure { textValue: show args.value, lastKnownValue: args.value }

    update state str =
      case Int.fromString str of
        Nothing ->
          pure state { textValue = str }
        Just n -> do
          forkVoid $ liftEffect $ args.onChange n
          pure { textValue: str, lastKnownValue: n }

    view state dispatch =
      H.input_ args.className
        { type: "number"
        , min: show args.min
        , max: show args.max
        , step: show args.step
        , onChange: dispatch <?| eventTargetValue
        , value:
            -- The idea here is that if the consumer has passed us a new value
            -- via props, we need to show this new value. Otherwise we show
            -- whatever the user has been editing.
            if args.value == state.lastKnownValue
              then state.textValue
              else show args.value
        }
