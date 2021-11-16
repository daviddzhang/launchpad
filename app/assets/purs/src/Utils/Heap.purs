module Utils.Heap
  ( trackEvent
  ) where

import Prelude

import Effect (Effect)
import Foreign.Object as FO

-- Wraps `heap.track`: https://docs.heap.io/reference#track
foreign import trackEvent :: String -> FO.Object String -> Effect Unit
