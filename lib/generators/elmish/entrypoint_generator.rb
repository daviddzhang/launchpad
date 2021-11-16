module Elmish
  class EntrypointGenerator < Rails::Generators::NamedBase
    desc "Creates an Elmish entrypoint file in app/assets/purs/src/EntryPoints"
    def create_entrypoint
      create_file "app/assets/purs/src/EntryPoints/#{name}.purs", <<~FILE
        module EntryPoints.#{name.gsub('/', '.')}
          ( boot
          ) where

        import Prelude

        import Data.Maybe (Maybe(..))
        import Elmish (BootRecord, ComponentDef, Dispatch, ReactElement, Transition)
        import Elmish.HTML.Styled as H
        import Foreign (Foreign)
        import Utils.Boot (bootOrPanic)

        boot :: BootRecord Foreign
        boot = bootOrPanic
          { def: Just <<< def
          , diagnosticName: "#{name}"
          }

        type Props = {}

        type State = Unit

        type Message = Void

        def :: Props -> ComponentDef Message State
        def _props =
          { init, update, view }
          where
            init :: Transition Message State
            init = pure unit

            update :: State -> Message -> Transition Message State
            update state _msg = pure state

            view :: State -> Dispatch Message -> ReactElement
            view _state _dispatch = H.empty
      FILE
    end
  end
end
