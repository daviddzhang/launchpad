module Elmish
  class ComponentGenerator < Rails::Generators::NamedBase
    desc "Creates an Elmish component in app/assets/purs/src"
    def create_component
      create_file "app/assets/purs/src/#{name}.purs", <<~FILE
        module #{name.gsub('/', '.')}
          ( Message(..)
          , State
          , init
          , update
          , view
          ) where

        import Prelude

        import Elmish (Dispatch, ReactElement, Transition)
        import Elmish.HTML.Styled as H

        type State = {}

        data Message
          = AddYourMessage

        init :: State
        init = {}

        update :: State -> Message -> Transition Message State
        update state = case _ of
          AddYourMessage -> pure state

        view :: State -> Dispatch Message -> ReactElement
        view _state _dispatch = H.empty
      FILE
    end
  end
end
