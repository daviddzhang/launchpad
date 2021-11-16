module Utils.Location
  ( ParsedLocation(..)
  , parseQueryString
  , updateUrl
  , urlWatcher
  , reloadPage
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe, fromMaybe)
import Data.Nullable as Nullable
import Data.String as String
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Elmish (Dispatch, ReactElement, mkEffectFn1)
import Foreign (unsafeToForeign)
import Foreign.Object as FO
import JSURI (decodeURIComponent)
import Utils.BrowserEvents (browserEvents)
import Utils.ErrorReporter as ErrorReporter
import Web.HTML as HTML
import Web.HTML.History as History
import Web.HTML.Location as Location
import Web.HTML.Window as Window

-- | Result of parsing a URL. There are three possible outcomes:
-- |
-- |  * ValidLocation       - successfully parsed.
-- |  * UnknownLocation     - no idea what this URL means.
-- |  * OutOfBoundsLocation - we recognize the URL, but we don't have enough
-- |     data locally to render what it's referring to. The current
-- |     implementation handles this case by reloading the page.
data ParsedLocation loc
  = ValidLocation loc
  | OutOfBoundsLocation
  | UnknownLocation
derive instance eqParsedLocation :: Eq loc => Eq (ParsedLocation loc)

-- This instance is required for tests
instance showParsedLocation :: Show loc => Show (ParsedLocation loc) where
  show = case _ of
    ValidLocation loc -> "ValidLocation " <> show loc
    OutOfBoundsLocation -> "OutOfBoundsLocation"
    UnknownLocation -> "UnknownLocation"

updateUrl :: { url :: String, replace :: Boolean } -> Effect Unit
updateUrl { url, replace } = do
  location <- HTML.window >>= Window.location
  currentUrl <- location # Location.pathname
  currentQs <- location # Location.search
  unless (currentUrl <> currentQs == url) $
    HTML.window >>= Window.history >>= setStateFn
      (unsafeToForeign Nullable.null)
      (History.DocumentTitle "CollegeVine")
      (History.URL url)

  where
    setStateFn
      | replace = History.replaceState
      | otherwise = History.pushState

urlWatcher :: forall loc.
  { parseLocation :: { path :: String, queryString :: String } -> ParsedLocation loc
  , onLocationChange :: Dispatch loc
  }
  -> ReactElement
urlWatcher { parseLocation, onLocationChange } =
  browserEvents
    { popstate: mkEffectFn1 \_ -> do
        location <- HTML.window >>= Window.location
        path <- location # Location.pathname
        queryString <- location # Location.search
        parseLocation { path, queryString } # case _ of
          UnknownLocation ->
            -- We failed to parse the URL, but it did come from `popstate`, so
            -- the browser must think it's ours to handle. Technically this
            -- Should Never Happen™, so we'll just ignore it, but report back to
            -- HQ for analysis.
            ErrorReporter.notify ErrorReporter.error
              "Failed to parse URL on popstate"
              { path, queryString }
              pure
          OutOfBoundsLocation ->
            -- The URL looks legit, but we can't render it with locally
            -- available data. This could happen if the user first loaded the
            -- page in state A, then navigated to state B, then reloaded the
            -- page, so that state A is no longer in memory, and then clicked
            -- "Back". In this case the only thing to do is reload the page. And
            -- in any other non-legit case reloading page is also a good
            -- default: after all, we don't recognize this URL.
            HTML.window >>= Window.location >>= Location.reload
          ValidLocation loc ->
            -- We successfully parsed the URL => pass it back to the consumer
            onLocationChange loc
    }

parseQueryString :: String -> FO.Object (Maybe String)
parseQueryString qs =
  qs
  # String.stripPrefix (String.Pattern "?")
  # fromMaybe qs
  # String.split (String.Pattern "&")
  # Array.filter (not String.null)
  <#> parseValue
  # FO.fromFoldable
  where
    parseValue s =
      let nameValue = String.split (String.Pattern "=") s
          name = Array.index nameValue 0 >>= decodeURIComponent # fromMaybe ""
          value = Array.index nameValue 1 >>= decodeURIComponent
      in Tuple name value

reloadPage :: Effect Unit
reloadPage = HTML.window >>= Window.location >>= Location.reload
