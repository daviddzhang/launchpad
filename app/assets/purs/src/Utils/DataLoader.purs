-- View-less wrapper around `XMLHttpRequest` to expose `progress` events that
-- are not supported in Affjax:
-- https://github.com/purescript-contrib/purescript-affjax/issues/50
module Utils.DataLoader
  ( Props
  , dataLoader
  , ProgressEvent
  ) where

import Prelude

import Elmish (EffectFn1, createElement')
import Elmish.React.Import (ImportedReactComponent, ImportedReactComponentConstructor, EmptyProps)
import Foreign (Foreign)

type ProgressEvent = Foreign

type Props r =
  ( onProgress :: EffectFn1 ProgressEvent Unit
  , onComplete :: EffectFn1 Foreign Unit
  , onError :: EffectFn1 String Unit
  , url :: String
  | r
  )

dataLoader :: ImportedReactComponentConstructor Props EmptyProps
dataLoader = createElement' _dataLoader

foreign import _dataLoader :: ImportedReactComponent
