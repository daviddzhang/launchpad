module Utils.Selection
  ( Selection
  , clearSelection
  , getSelection
  , isEmptySelection
  , selectionEndNode
  , selectionStartNode
  ) where

import Prelude

import Effect (Effect)
import Web.DOM (Node)

-- | Document text selection
foreign import data Selection :: Type

foreign import getSelection :: Effect Selection
foreign import selectionStartNode :: Selection -> Effect Node
foreign import selectionEndNode :: Selection -> Effect Node
foreign import clearSelection :: Selection -> Effect Unit
foreign import isEmptySelection :: Selection -> Effect Boolean
