module Utils.DateTime
  ( localTimeZoneName
  , nowAsLocalTime
  , pageLoadLocalTime
  , parseAsLocalTime
  ) where

import Prelude

import Data.DateTime (DateTime(..), Time(..), canonicalDate)
import Data.Enum (toEnum)
import Data.JSDate as JSDate
import Data.Maybe (Maybe(..), maybe)
import Effect (Effect)
import Effect.Exception (throw)
import Effect.Unsafe (unsafePerformEffect)

-- | Parses the given string as a date (in ISO format), then converts to
-- | `DateTime` expressed as browser-local time. The std library `JSDate` module
-- | doesn't have a facility for exactly this, and the facilities that it does
-- | have insist on being effectful, which is super inconvenient.
parseAsLocalTime :: String -> Maybe DateTime
parseAsLocalTime str =
  parseAsLocalTime_ { just: Just, nothing: Nothing } str
  <#> jsDateToRecord_
  >>= fromRecord

-- | Returns current time in machine-local timezone, unlike the standard library
-- | function `nowDateTime` (from `purescript-now`), which returns time in UTC.
nowAsLocalTime :: Effect DateTime
nowAsLocalTime = jsToPurs =<< jsDateNow_

-- | Browser-local time when the current page was loaded. It's a function from
-- | `Unit`, rather than just a value, so that we can perform clever
-- | shenannigans under Node vs. Browser. See comments in the foreign module for
-- | explanation.
pageLoadLocalTime :: Unit -> DateTime
pageLoadLocalTime _ = unsafePerformEffect $ jsToPurs =<< jsPageLoadLocalTime_

fromRecord :: JsDateRecord -> Maybe DateTime
fromRecord d = do
  year <- toEnum d.year
  month <- toEnum (d.month + 1) -- JS counts months from zero, DateTime - from one
  day <- toEnum d.day
  hour <- toEnum d.hour
  minute <- toEnum d.minute
  second <- toEnum d.second
  millisecond <- toEnum d.millisecond
  pure $ DateTime (canonicalDate year month day) (Time hour minute second millisecond)

type JsDateRecord =
  { year :: Int
  , month :: Int
  , day :: Int
  , hour :: Int
  , minute :: Int
  , second :: Int
  , millisecond :: Int
  }

jsToPurs :: JSDate.JSDate -> Effect DateTime
jsToPurs jsDate =
  jsDate
  # jsDateToRecord_
  # fromRecord
  # maybe panic pure
  where
    panic = throw "Failed to obtain current time. This should never happen."

foreign import parseAsLocalTime_ :: forall a. { just :: JSDate.JSDate -> a, nothing :: a } -> String -> a
foreign import jsDateToRecord_ :: JSDate.JSDate -> JsDateRecord
foreign import jsDateNow_ :: Effect JSDate.JSDate
foreign import jsPageLoadLocalTime_ :: Effect JSDate.JSDate

-- | Returns abbreviated name of the local time zone, like EDT or PST. There no
-- | direct browser support for this, so implementation is based on a series of
-- | hacks - see comments in the foreign module.
foreign import localTimeZoneName :: String

