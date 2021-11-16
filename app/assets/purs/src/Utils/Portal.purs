module Utils.Portal
  ( portal
  , mockPortal
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Elmish (ReactElement, forks)
import Elmish.Component (ComponentName(..), wrapWithLocalState)
import Test.Cleanup (class MonadCleanup, CleanupT, cleanupAction)
import Utils.HTML (elementById', maybeHtml)
import Utils.ReactDOM as ReactDOM
import Web.DOM.Document (createElement)
import Web.DOM.Element as Element
import Web.DOM.Node (appendChild)
import Web.HTML (window)
import Web.HTML.HTMLDocument (body, toDocument)
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window (document)

-- | Portals allow rendering content outside of the current render tree. This
-- | helper on top of `ReactDOM.createPortal` accepts an id and some content and
-- | either creates a div with the given id or just adds the given content to
-- | that div if it aleady exists. This is useful sometimes for overlays. See
-- | https://reactjs.org/docs/portals.html for more info.
portal :: String -> ReactElement -> ReactElement
portal id content =
  if unsafePerformEffect $ Ref.read mockPortal__
    then content
    else portal' { id, content }

portal' :: { id :: String, content :: ReactElement } -> ReactElement
portal' = wrapWithLocalState (ComponentName "Portal") \{ id, content } ->
  { init: do
      forks \dispatch -> liftEffect $ do
        mContainer <- elementById' id
        case mContainer of
          Just container ->
            dispatch container
          Nothing -> do
            doc <- document =<< window
            mBody <- body doc
            for_ mBody \b -> do
              container <- createElement "div" $ toDocument doc
              Element.setId id container
              appendChild (Element.toNode container) (HTMLElement.toNode b)
              dispatch container
      pure Nothing
  , update: \_ container -> pure $ Just container
  , view: \container _ ->
      maybeHtml container $
        ReactDOM.createPortal content
  }

----------------------
-- Mock for testing --
----------------------

-- | Stubs the portal for the purposes of testing, since Enzyme doesn’t support
-- | portals.
mockPortal :: forall m. MonadEffect m => MonadCleanup m => CleanupT m Unit
mockPortal = do
  liftEffect $ Ref.write true mockPortal__
  cleanupAction $ liftEffect $ Ref.write false mockPortal__

mockPortal__ :: Ref Boolean
mockPortal__ = unsafePerformEffect $ Ref.new false
