module Utils.ButtonTo
  ( buttonTo
  ) where


import Elmish (ReactElement)
import Elmish.HTML.Styled as H

type Args =
  { label :: String
  , path :: String
  , token :: String
  }

buttonTo :: String -> Args -> ReactElement
buttonTo className args =
  H.form_ "d-inline"
    { method: "post"
    , action: args.path
    }
    [ H.input_ className
        { type: "submit"
        , value: args.label
        }
    , H.input_ ""
        { type: "hidden"
        , name: "authenticity_token"
        , value: args.token
        }
    ]
