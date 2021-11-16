module Utils.Json
  ( jsonLdTag
  , parse
  , stringify
  ) where

import Data.Maybe (Maybe(..))
import Elmish (ReactElement)
import Elmish.Foreign (class CanPassToJavaScript)
import Elmish.HTML as H
import Foreign (Foreign)

parse :: String -> Maybe Foreign
parse = parse_ { nothing: Nothing, just: Just }
foreign import parse_ :: forall a. { nothing :: a, just :: Foreign -> a } -> String -> a

stringify :: forall a. CanPassToJavaScript a => a -> String
stringify = stringify_
foreign import stringify_ :: forall a. a -> String

jsonLdTag :: forall r. CanPassToJavaScript (Record r) => Record r -> ReactElement
jsonLdTag content = H.script
  { type: "application/ld+json"
  , dangerouslySetInnerHTML: { __html: stringify content }
  }
  ([] :: Array ReactElement)
