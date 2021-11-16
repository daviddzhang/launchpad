module Utils.ReactDOM
  ( createPortal
  ) where

import Data.Function.Uncurried (Fn2, runFn2)
import Elmish (ReactElement)
import Web.DOM (Element)

createPortal :: ReactElement -> Element -> ReactElement
createPortal = runFn2 createPortal_

foreign import createPortal_ :: Fn2 ReactElement Element ReactElement
