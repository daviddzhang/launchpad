module Utils.Foreign
  ( parse
  ) where

import Prelude

import Control.Monad.Except (Except, runExcept)
import Data.Either (hush)
import Data.Maybe (Maybe)
import Foreign (MultipleErrors)

parse :: forall a. Except MultipleErrors a -> Maybe a
parse = hush <<< runExcept
