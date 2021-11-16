module Utils.URL
  ( canonicalize
  ) where

import Prelude

import Data.Maybe (fromMaybe)
import Data.String as String

canonicalize :: String -> { siteName :: String, url :: String }
canonicalize url = { siteName, url: "http://" <> addr }
  where
    addr = url # removePrefix "http://" # removePrefix "https://"
    siteName = addr # removePrefix "www." # removeSuffix "/"

    removePrefix p s =
      s # String.stripPrefix (String.Pattern p) # fromMaybe s

    removeSuffix p s =
      s # String.stripSuffix (String.Pattern p) # fromMaybe s
