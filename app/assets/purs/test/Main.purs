module Test.Main where

import Prelude

import Effect (Effect)
import Test.Chancing.Guidance.Types.ApplyTestOptionalGuidanceSpec as ApplyTestOptionalGuidance
import Test.Chancing.Guidance.Types.ApplyWithTestGuidanceSpec as ApplyWithTestGuidance
import Test.Community.CommunityPageSpec as CommunityPage
import Test.Component.DropdownSpec as Dropdown
import Test.Enzyme as Enzyme
import Test.Hub.ImpersonationSpec as Impersonation
import Test.HubSpec as Hub
import Test.Monad (runSpec)
import Test.SchoolDetails.Chancing.GuidanceSpec as Guidance
import Test.Utils.Format as Format
import Test.Utils.JsonParseSpec as JsonParse
import Test.Utils.LocationSpec as Location
import Test.Utils.Markdown as Markdown
import Test.Utils.NaturalOrder as NaturalOrder
import Test.Utils.TextSpec as Text

main :: Effect Unit
main = do
  Enzyme.configure
  runSpec do
    ApplyTestOptionalGuidance.spec
    ApplyWithTestGuidance.spec
    CommunityPage.spec
    Dropdown.spec
    Format.spec
    Guidance.spec
    Hub.spec
    Impersonation.spec
    JsonParse.spec
    Location.spec
    Markdown.spec
    NaturalOrder.spec
    Text.spec

-- This import is only here to cause the FFI code to run, so that jsdom can be
-- run before React.
-- See https://enzymejs.github.io/enzyme/docs/guides/jsdom.html for more info.
foreign import _configureJsDomViaFfi :: Type
