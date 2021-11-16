module Utils.Boot
  ( bootOrPanic
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe, maybe)
import Elmish (ComponentDef)
import Elmish as Elmish
import Elmish.Foreign (class CanReceiveFromJavaScript, readForeign')
import Elmish.React.DOM as R
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)
import Utils.Parse (parseOrPanic)

-- | A specialized version of `parseOrPanic` intended for creating a boot
-- | record. It validates the incoming props and falls back to an empty screen
-- | if the props are of the wrong type. As a possible enhancement, we can make
-- | it display a nice "oops" page instead of a blank screen.
bootOrPanic :: forall props msg state. CanReceiveFromJavaScript props =>
  { def :: props -> Maybe (ComponentDef msg state)
  , diagnosticName :: String
  }
  -> Elmish.BootRecord Foreign
bootOrPanic { def, diagnosticName } =
  Elmish.boot $ parseOrPanic
    { parse: \fProps -> do
        props <- readForeign' fProps
        def props # maybe (Left "Component construction failed") Right

    , diagnosticName:
        "Props for " <> diagnosticName

    , default:
        -- This is just empty screen, with `init` and `update` unsafeCoerced to
        -- the right types, which is safe here, because the state isn't used in
        -- the view.
        { init: pure $ unsafeCoerce unit
        , update: \_ _ -> pure $ unsafeCoerce unit
        , view: \_ _ -> R.empty
        }
    }
