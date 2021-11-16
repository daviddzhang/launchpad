module Utils.HTML
  ( div_
  , attribute
  , documentVisibilityState
  , elementById
  , elementById'
  , elementFromPoint
  , emdash
  , eventTarget
  , eventTargetCurrentTime
  , eventTargetValue
  , highlight
  , htmlIf
  , htmlIfForce
  , htmlUnless
  , inputElementById
  , join
  , maybeHtml
  , maybeHtml'
  , navigateTo
  , nbsp
  , textAreaCaretCoordinates
  , video_
  , scrollToTop
  ) where

import Prelude

import Affjax (URL)
import Data.Array (elem, intersperse)
import Data.Array as Array
import Data.Foldable (intercalate)
import Data.Lazy (Lazy, force)
import Data.Maybe (Maybe, fromMaybe, maybe)
import Data.String as String
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn2)
import Elmish (ReactElement)
import Elmish.Foreign (class CanReceiveFromJavaScript, readForeign)
import Elmish.HTML as H
import Elmish.HTML.Internal as I
import Foreign (Foreign)
import Foreign.Object as F
import Web.DOM as WD
import Web.DOM.NonElementParentNode (getElementById) as W
import Web.HTML (HTMLElement, HTMLInputElement, window) as W
import Web.HTML as HTML
import Web.HTML.HTMLDocument (toNonElementParentNode) as W
import Web.HTML.HTMLElement (fromElement) as W
import Web.HTML.HTMLInputElement as Input
import Web.HTML.Location (setHref) as Location
import Web.HTML.Window (document) as W
import Web.HTML.Window as Window

-- Get an HTML element, given its ID
elementById :: String -> Effect (Maybe W.HTMLElement)
elementById id =
  elementById' id
  <#> (_ >>= W.fromElement)

elementById' :: String -> Effect (Maybe WD.Element)
elementById' id =
  W.window
  >>= W.document
  <#> W.toNonElementParentNode
  >>= W.getElementById id

inputElementById :: String -> Effect (Maybe W.HTMLInputElement)
inputElementById id = (Input.fromHTMLElement =<< _) <$> elementById id

eventTarget :: forall a. CanReceiveFromJavaScript a => Foreign -> Maybe a
eventTarget = attribute "target"

attribute :: forall a. CanReceiveFromJavaScript a => String -> Foreign -> Maybe a
attribute name = readForeign >=> F.lookup name >=> readForeign

-- Get the value of the target passed to a JavaScript event
eventTargetValue :: Foreign -> Maybe String
eventTargetValue = eventTarget >=> attribute "value"

eventTargetCurrentTime :: Foreign -> Maybe Number
eventTargetCurrentTime = eventTarget >=> attribute "currentTime"

htmlIf :: Boolean -> ReactElement -> ReactElement
htmlIf shouldRender html
  | shouldRender = html
  | otherwise = H.empty

htmlIfForce :: Boolean -> Lazy ReactElement -> ReactElement
htmlIfForce shouldRender html
  | shouldRender = force html
  | otherwise = H.empty

htmlUnless :: Boolean -> ReactElement -> ReactElement
htmlUnless shouldNotRender html
  | shouldNotRender = H.empty
  | otherwise = html

maybeHtml :: forall a. Maybe a -> (a -> ReactElement) -> ReactElement
maybeHtml = flip (maybe H.empty)

maybeHtml' :: Maybe ReactElement -> ReactElement
maybeHtml' = fromMaybe H.empty

nbsp :: ReactElement
nbsp = H.text "\xA0"

emdash :: ReactElement
emdash = H.text "\x2014"

join :: ReactElement -> Array ReactElement -> ReactElement
join separator =
  H.fragment <<< intercalate [separator] <<< map Array.singleton

foreign import documentVisibilityState :: Effect Boolean

elementFromPoint :: { x :: Number, y :: Number } -> Effect W.HTMLElement
elementFromPoint { x, y } = runEffectFn2 elementFromPoint_ x y

foreign import elementFromPoint_ :: EffectFn2 Number Number W.HTMLElement

-- UIs with pagination, e.g. wizards, can benefit from explicitly resetting
-- scroll position after paginating.
--
-- NOTE: PureScript has no bindings to `scrollTo`, so we implement our own.
foreign import scrollToTop :: Effect Unit

type OptProps_div r =
  ( onTouchStart :: EffectFn1 Foreign Unit
  , onTouchMove :: EffectFn1 Foreign Unit
  | H.OptProps_div r
  )

div_ = I.styledTag_ "div" :: I.StyledTag_ OptProps_div

type OptProps_video r =
  ( onPlay :: EffectFn1 Foreign Unit
  , onPause :: EffectFn1 Foreign Unit
  | H.OptProps_video r
  )

video_ = I.styledTag_ "video" :: I.StyledTag_ OptProps_video

navigateTo :: URL -> Effect Unit
navigateTo href = Location.setHref href =<< Window.location =<< HTML.window

-- | For any words in the given text that are members of the given array,
-- | surrounds them in a `<mark>` tag.
highlight :: String -> Array String -> ReactElement
highlight text [] = H.text text
highlight text words = H.fragment $
  text
  # String.split (String.Pattern " ")
  <#> (\w -> (if w `elem` words then H.mark {} else H.text) w)
  # intersperse (H.text " ")

foreign import textAreaCaretCoordinates :: HTML.HTMLTextAreaElement -> Effect { x :: Int, y :: Int }
