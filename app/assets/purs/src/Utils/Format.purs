module Utils.Format
  ( timeDiff
  , timeDiffLongFormat, timeDiffLongFormat'
  , timeDiffShortFormat, timeDiffShortFormat'

  , int
  , number
  , percent
  , percentCss
  , priceUSD
  , priceUSDWithCents
  , durationString

  -- Pluralization
  , pluralize
  , pluralize'
  , Singular(..)
  , Plural(..)
  ) where

import Prelude

import Data.DateTime as D
import Data.Enum (fromEnum)
import Data.Formatter.Number (formatOrShowNumber)
import Data.Int (floor, round, toNumber)
import Data.Int as Int
import Data.Time.Duration (Minutes(..))
import Data.Undefined.NoProblem (Opt, (!))
import Data.Undefined.NoProblem.Closed as Closed
import Math ((%))
import Safe.Coerce (coerce)

int :: Int -> String
int = number <<< Int.toNumber

number :: Number -> String
number = formatOrShowNumber "0,0"

priceUSD :: Number -> String
priceUSD value = "$" <> number value

priceUSDWithCents :: Number -> String
priceUSDWithCents value = "$" <> formatOrShowNumber "0,0.00" value

percent :: Number -> String
percent value =
  show (round (value * 100.0)) <> "%"

-- | Unlike `percent`, this function is intended to be used for CSS property
-- | values, such as `width` or `height`, and not for user display. This is why
-- | it's a separate function: if we decide at some point to change how we
-- | format percentages, it shouldn't break our CSS.
percentCss :: Number -> String
percentCss value =
  show (round (value * 100.0)) <> "%"

-- Basic pluralization for the English language without the overhead of `Intl`
-- API:
newtype Singular = Singular String
newtype Plural = Plural String

-- Returns quantity and noun with proper inflection.
pluralize :: Int -> Singular -> Plural -> String
pluralize quantity singular plural =
  show quantity <> " " <> pluralize' quantity singular plural

-- Returns noun only with proper inflection.
pluralize' :: Int -> Singular -> Plural -> String
pluralize' quantity (Singular singular) (Plural plural) =
  if quantity == 1 then singular else plural

type TimeDiffFormat = { minutes :: Int, hours :: Int, days :: Int, months :: Int, years :: Int } -> String

type TimeDiffArgs =
  { from :: D.DateTime
  , to :: D.DateTime
  , format :: Opt TimeDiffFormat
  }

timeDiff :: forall args. Closed.Coerce args TimeDiffArgs => args -> String
timeDiff args' = format { minutes, hours, days, months, years }
  where
    args = Closed.coerce args' :: TimeDiffArgs
    format = args.format ! timeDiffLongFormat "ago"

    minutes = round $ coerce (D.diff args.to args.from :: Minutes)
    hours = (minutes + 30) / 60
    days = (hours + 12) / 24
    months = totalMonths args.to - totalMonths args.from
    years = (months + 6) / 12

    totalMonths d = (fromEnum $ D.year $ D.date d) * 12 + (fromEnum $ D.month $ D.date d)

-- | Minutes, hours, days, years are denoted as m, h, d, y respectively, and
-- | months are not included at all, so 65 days would be formatted as "65d"
-- | instead of "2 months ago".
timeDiffShortFormat :: TimeDiffFormat
timeDiffShortFormat = timeDiffShortFormat' { justNow: "now" }

-- | Default date diff "time ago" format - e.g. "just now", "5 minutes ago", "a
-- | month ago", "3 years ago"
timeDiffLongFormat :: String -> TimeDiffFormat
timeDiffLongFormat suffix = timeDiffLongFormat' { suffix: " " <> suffix, justNow: "just now" }

timeDiffShortFormat' :: { justNow :: String } -> TimeDiffFormat
timeDiffShortFormat' args a
  | a.minutes <= 0 = args.justNow
  | a.minutes <= 45 = show a.minutes <> "m"
  | a.hours < 24 = show a.hours <> "h"
  | a.days <= 340 = show a.days <> "d"
  | otherwise = show a.years <> "y"

timeDiffLongFormat' :: { suffix :: String, justNow :: String } -> TimeDiffFormat
timeDiffLongFormat' args a
  | a.minutes <= 0 = args.justNow
  | a.minutes <= 1 = "a minute" <> args.suffix
  | a.minutes <= 45 = show a.minutes <> " minutes" <> args.suffix
  | a.hours <= 1 = "an hour" <> args.suffix
  | a.hours < 24 = show a.hours <> " hours" <> args.suffix
  | a.days <= 1 = "a day" <> args.suffix
  | a.days < 30 = show a.days <> " days" <> args.suffix
  | a.months <= 1 = "a month" <> args.suffix
  | a.months < 12 = show a.months <> " months" <> args.suffix
  | a.years <= 1 = "a year" <> args.suffix
  | otherwise = show a.years <> " years" <> args.suffix

-- Converts a duration in seconds to string in the format of "<minutes>:<seconds>"
durationString :: Int -> String
durationString seconds = do
  let minutes = show $ seconds / 60
  minutes <> ":" <> remainderSeconds

  where
    remainderSeconds = do
      let remainder = toNumber seconds % 60.0
      if remainder < 10.0
        then "0" <> show (floor remainder)
        else show (floor remainder)
