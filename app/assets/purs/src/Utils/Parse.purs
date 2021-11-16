module Utils.Parse
  ( class ParseOrPanic
  , parseOrPanic
  , parseOrPanic'
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..), maybe)
import Utils.ErrorReporter as ErrorReporter

class ParseOrPanic f where
  -- | Attempts to parse a raw value `a` (usually a string) into a structured
  -- | value `b` using the provided `parse` function, and if that fails (as
  -- | indicated by `Nothing` or `Left` result), returns the given value
  -- | `default`, while also printing out an error in console and notifying
  -- | ErrorReporter, so we can quickly fix the issue.
  -- |
  -- | The `parse` function may return `Maybe a` or `Either String a` when there
  -- | is a way or need to provide additional error information.
  -- |
  -- | Intended to be partially applied to obtain a Maybe-less parsing function.
  -- | For example:
  -- |
  -- |     parse :: String -> Foo
  -- |     parse = parseOrPanic
  -- |       { parse: fooFromString
  -- |       , default: dummyFooValue
  -- |       , diagnosticName: "Foo"
  -- |       }
  -- |
  -- |     fooFromString :: String -> Maybe Foo
  -- |     dummyFooValue :: Foo
  -- |
  parseOrPanic :: forall a b.
    { parse :: a -> f b
    , default :: b
    , diagnosticName :: String
    }
    -> a
    -> b

instance ParseOrPanic (Either String) where
  parseOrPanic { parse, default, diagnosticName } a =
    case parse a of
      Right b ->
        b
      Left error ->
        ErrorReporter.notify
          ErrorReporter.error
          ("Failed to parse " <> diagnosticName)
          { error, value: a }
          \_ -> default

instance ParseOrPanic Maybe where
  parseOrPanic args =
    parseOrPanic args { parse = args.parse >>> maybe (Left "") Right }

-- | Alternative to `parseOrPanic` in case there is no reasonable default value.
parseOrPanic' :: forall a b f. ParseOrPanic f => Functor f =>
  { parse :: a -> f b
  , diagnosticName :: String
  }
  -> a
  -> Maybe b
parseOrPanic' { parse, diagnosticName } =
  parseOrPanic { parse: \raw -> Just <$> parse raw, default: Nothing, diagnosticName }
