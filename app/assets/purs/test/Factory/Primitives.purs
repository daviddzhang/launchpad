module Primitives
  ( chooseBool
  ) where

import Control.Monad.Gen as MG
import Test.QuickCheck.Gen (Gen)

-- | Helper that’s not polymorphic over a monad, so that `chooseBool` can be
-- | used with `genRecord` without a type signature
chooseBool :: Gen Boolean
chooseBool =
  MG.chooseBool
