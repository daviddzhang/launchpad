module Utils.LoginButton
  ( Auth0Tab, auth0TabLogin, auth0TabSignup
  , loginButton
  ) where

import Prelude

import Data.DateTime (adjust)
import Data.JSDate as JSDate
import Data.Maybe (fromMaybe)
import Data.Time.Duration (Minutes(..))
import Data.Undefined.NoProblem (Opt, (!))
import Data.Undefined.NoProblem.Closed as Closed
import Effect.Now (nowDateTime)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Elmish (ReactElement)
import Elmish.HTML.Styled as H
import Utils.API as API

type Args =
  { text :: Opt String
  , className :: Opt String
  , auth0ActiveTab :: Opt Auth0Tab
  , openInNewTab :: Opt Boolean
  }

loginButton :: forall args
   . Closed.Coerce args Args
  => args
  -> ReactElement
loginButton args' =
  H.form_ "d-inline"
    { method: "post"
    , action: path
    , target: if args.openInNewTab ! false then "_blank" else ""
    }
    [ H.input_ ("btn " <> (args.className ! "btn-primary px-4"))
        { type: "submit"
        , value: args.text ! "Log in"
        , onClick: setAuth0Cookie
        }
    , H.input_ ""
        { type: "hidden"
        , name: "authenticity_token"
        , value: token
        }
    ]
  where
    args = Closed.coerce args' :: Args

    setAuth0Cookie = do
      now <- nowDateTime
      let expiration = adjust (Minutes 5.0) now # fromMaybe now
          strExpiration = expiration # JSDate.fromDateTime # JSDate.toUTCString
      runEffectFn1 setCookie $
        "initialTab=" <> initialTab <> ";domain=.collegevine.com;path=/;expires=" <> strExpiration

    initialTab = let Auth0Tab t = args.auth0ActiveTab ! auth0TabLogin in t

    { path, token } =
      API.unsafeGetEndpoint "login_path"
      # fromMaybe { path: "", token: "" }

newtype Auth0Tab = Auth0Tab String

auth0TabLogin = Auth0Tab "login" :: Auth0Tab
auth0TabSignup = Auth0Tab "signUp" :: Auth0Tab

foreign import setCookie :: EffectFn1 String Unit
