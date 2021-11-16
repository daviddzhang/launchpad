module Utils.Record
  ( trim
  ) where

import Elmish.React.Import (class IsSubsetOf)
import Unsafe.Coerce (unsafeCoerce)

-- | Trims a record down to a subset of its fields
trim :: forall a b. IsSubsetOf b a => Record a -> Record b
trim = unsafeCoerce
