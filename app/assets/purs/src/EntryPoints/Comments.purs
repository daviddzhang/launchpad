module EntryPoints.Comments
  ( boot
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Elmish (BootRecord, ComponentDef, Dispatch, ReactElement, Transition, handleMaybe)
import Elmish.Foreign (Foreign)
import Elmish.HTML.Styled as H
import Utils.Boot (bootOrPanic)
import Utils.HTML (eventTargetValue)
-- import Utils.API as API

boot :: BootRecord Foreign
boot = bootOrPanic
  { def: Just <<< def
  , diagnosticName: "Demo"
  }

data Message
  = Create
  | CommentTextChanged String
  | CommenterChanged String

type Props =
  { comments :: Array Comment
  }

type Comment = 
  { commenter :: String 
  , comment :: String 
  }

type State = 
  { commenter :: String
  , newComment :: String
  , comments :: Array Comment
  }

def :: Props -> ComponentDef Message State
def props =
  { init, update, view }
  where
    init :: Transition Message State
    init = 
      pure
        { newComment: ""
        , commenter : ""
        , comments: props.comments }


    update :: State -> Message -> Transition Message State
    update state = case _ of
      CommentTextChanged updatedComment ->
        pure state 
          { newComment = updatedComment }

      CommenterChanged updatedCommenter ->
        pure state 
          { commenter = updatedCommenter }
        
      Create ->
        pure state 
          {
            comments = Array.snoc state.comments { commenter: state.commenter, comment: state.newComment }
          , commenter = ""
          , newComment = ""
          }

    view :: State -> Dispatch Message -> ReactElement
    view state dispatch = 
      H.fragment
        [ H.h3 "" "Comments"
        , H.ul "" $
            (\comment -> H.li ""
                          [ H.div "row" 
                            [ H.text comment.comment ]
                          , H.div "row"
                            [ H.text comment.commenter ] 
                          ]
            ) <$> state.comments

        , H.input_ "row" 
          { type: "text"
          , value: state.commenter
          , onChange: handleMaybe dispatch \e -> CommenterChanged <$> eventTargetValue e
          , placeholder: "Enter your name here"
          }
        , H.input_ "row" 
          { type: "text"
          , value: state.newComment
          , onChange: handleMaybe dispatch \e -> CommentTextChanged <$> eventTargetValue e
          , placeholder: "Enter your comment here"
          }
        , H.button_ 
            "btn btn-primary"
            { onClick: dispatch Create } 
            "Create"
        ]   
