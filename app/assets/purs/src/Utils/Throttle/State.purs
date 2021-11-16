module Utils.Throttle.State
  ( State
  , ThrottleState(..)
  , Message(..)
  ) where

import Data.Time.Duration (Milliseconds)

type State msg =
  { throttleState :: ThrottleState msg
  , delay :: Milliseconds
  }

data ThrottleState msg
  = Ready
  | Throttling msg

data Message msg
  = Request msg
  | Dispatch
