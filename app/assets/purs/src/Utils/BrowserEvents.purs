-- This is a dummy component that doesn't have any visual representation, but
-- serves only to intercept global browser events, such as 'resize'. This
-- component attaches event handlers on mount and detaches them on dismount.
module Utils.BrowserEvents
  ( Event
  , Props
  , browserEvents
  ) where

import Prelude

import Elmish (EffectFn1, createElement')
import Elmish.React.Import (ImportedReactComponent, ImportedReactComponentConstructor, EmptyProps)
import Foreign (Foreign)

type Event = Foreign

type Props r =
  ( hashchange :: EffectFn1 Event Unit
  , keyup :: EffectFn1 Event Unit
  , mousemove :: EffectFn1 Event Unit
  , mouseup :: EffectFn1 Event Unit
  , popstate :: EffectFn1 Event Unit
  , resize :: EffectFn1 Event Unit
  , selectionchange :: EffectFn1 Event Unit
  , visibilitychange :: EffectFn1 Event Unit
  , message :: EffectFn1 Event Unit
  | r
  )

browserEvents :: ImportedReactComponentConstructor EmptyProps Props
browserEvents = createElement' _browserEvents

foreign import _browserEvents :: ImportedReactComponent
