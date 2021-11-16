module Utils.BlurInput
  ( blurInput
  ) where

import Prelude

import Data.Undefined.NoProblem (Opt, (!))
import Data.Undefined.NoProblem.Closed as Opt
import Elmish (ComponentDef, Dispatch, ReactElement, (<?|))
import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Elmish.HTML.Styled as H
import Utils.HTML (eventTargetValue)

type Args =
  { className :: String
  , value :: String
  , placeholder :: Opt String
  , onChange :: Dispatch String
  }

-- | A textbox that maintains the text value by itself and reports a change on
-- | blur. It's used in circumstances where the value can't be immediately
-- | updated as the user types in whatever data structure it's kept in, because
-- | it would cause other undesirable effects, such as premature resorting in
-- | Hub as the user edits notes or custom fields.
blurInput :: forall args. Opt.Coerce args Args => args -> ReactElement
blurInput = wrapWithLocalState (ComponentName "BlurInput") $ def <<< Opt.coerce

data Message
  = TextChanged String
  | ChangeReported

type State =
  { currentValue :: String
  , lastReportedValue :: String
  }

def :: Args -> ComponentDef Message State
def args = { init, view, update }
  where
    init = pure { currentValue: args.value, lastReportedValue: args.value }

    update state (TextChanged str) = pure state { currentValue = str }
    update state ChangeReported = pure state { lastReportedValue = state.currentValue }

    view state dispatch =
      H.input_ args.className
        { type: "text"
        , placeholder: args.placeholder ! ""
        , onChange: dispatch <?| \e -> TextChanged <$> eventTargetValue e
        , onBlur:
            if state.currentValue /= state.lastReportedValue
              then args.onChange state.currentValue *> dispatch ChangeReported
              else pure unit
        , value:
            -- The idea here is that if the consumer has passed us a new value
            -- via props, we need to show this new value. Otherwise we show
            -- whatever the user has been editing.
            if args.value == state.lastReportedValue
              then state.currentValue
              else args.value
        }
