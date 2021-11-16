module Test.Component.DropdownSpec
  ( spec
  ) where

import Prelude

import Component.Dropdown as Dropdown
import Elmish.HTML.Styled as H
import Test.Enzyme.EnzymeM as EM
import Test.Monad (Spec)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "Dropdown" do
  it "displays button" $
    EM.testElement (dropdown props) do
      EM.withSelector "button.t--toggle" $
        EM.text >>= shouldEqual "Click"
  it "toggles content" $
    EM.testElement (dropdown props) do
      EM.exists ".dropdown-menu" >>= shouldEqual false
      EM.clickOn "button.t--toggle"
      EM.withSelector ".dropdown-menu" $
        EM.text >>= shouldEqual "Some content"
  where
    dropdown =
      Dropdown.dropdown "t--dropdown"
    props =
      { toggleClass: "t--toggle"
      , toggleContent: H.text "Click"
      , content: \{ className } ->
          H.div className "Some content"
      }
