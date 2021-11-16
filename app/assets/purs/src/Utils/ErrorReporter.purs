module Utils.ErrorReporter
  ( notify
  -- severity
  , Severity
  , info
  , warning
  , error
  ) where

import Prelude

newtype Severity = Severity String

info :: Severity
info = Severity "info"

warning :: Severity
warning = Severity "warning"

error :: Severity
error = Severity "error"

-- | Notifies our error reporting service, but without introducing `Effect` or
-- | `Aff`. Takes a severity level, an error message and a record of "params",
-- | pushes them to ErrorReporter, as well as to `console`, then executes the
-- | given continuation and returns its result. This is the same way that
-- | `Debug.Trace.trace` works.
-- |
-- | For example:
-- |
-- |     case parseThing rawThing of
-- |       Just thing ->
-- |         "the thing is: " <> show thing
-- |       Nothing ->
-- |         ErrorReporter.notify
-- |           ErrorReporter.error
-- |           "Unable to parse a thing"
-- |           { raw: rawThing }
-- |           \_ -> "there is no thing"
-- |
foreign import notify ::
  forall a params.
  Severity ->
  String ->
  Record params ->
  (Unit -> a) ->
  a
