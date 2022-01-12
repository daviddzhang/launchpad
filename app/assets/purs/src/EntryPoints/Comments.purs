module EntryPoints.Comments
  ( Comment
  , boot
  )
  where

import Prelude

import Effect.Aff (Aff)
import Data.Int as Int
import Data.Array as Array
import Data.Maybe (Maybe(..))
import Elmish (BootRecord, ComponentDef, Dispatch, ReactElement, Transition, handleMaybe, forkVoid)
import Elmish.Foreign (Foreign)
import Elmish.HTML.Styled as H
import Utils.Boot (bootOrPanic)
import Utils.HTML (eventTargetValue)
import Utils.API as API

boot :: BootRecord Foreign
boot = bootOrPanic
  { def: Just <<< def
  , diagnosticName: "Demo"
  }

data Message
  = Create
  | CommentTextChanged String
  | CommenterChanged String
  | Upvote Int
  | Downvote Int

type Props =
  { comments :: Array Comment
  , postId :: Int
  }

type Comment = 
  { commenter :: String 
  , comment :: String 
  , upvotes :: Int
  , downvotes :: Int
  , id :: Int
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
    update state (CommentTextChanged updatedComment) = do
        pure state 
          { newComment = updatedComment }

    update state (CommenterChanged updatedCommenter) = do
        pure state 
          { commenter = updatedCommenter }
        
    update state Create = do
        forkVoid (createComment props.postId state.commenter state.newComment)
        pure state 
          {
            comments = Array.snoc state.comments { commenter: state.commenter, comment: state.newComment, upvotes: 0, downvotes: 0, id: 1 + (Array.length state.comments) }
          , commenter = ""
          , newComment = ""
          }

    update state (Upvote commentId) = do
      forkVoid (upvoteComment commentId)
      pure state
        {
          comments = 
            (\comment ->
              comment { upvotes = 
                        (if comment.id == commentId then comment.upvotes + 1 else comment.upvotes) 
                      }
            ) <$> state.comments
        }

    update state (Downvote commentId) = do
      forkVoid (downvoteComment commentId)
      pure state
        {
          comments = 
            (\comment ->
              comment { downvotes = 
                        (if comment.id == commentId then comment.downvotes + 1 else comment.downvotes) 
                      }
            ) <$> state.comments
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
                          , H.div "row"
                            [ H.text $ "Upvotes:" <> Int.toStringAs Int.decimal comment.upvotes
                            , H.button_ 
                                "btn btn-secondary"
                                { onClick: dispatch $ Upvote comment.id }
                                "Upvote"
                            ]
                          , H.div "row"
                            [ H.text $ "Downvotes:" <> Int.toStringAs Int.decimal comment.downvotes
                            , H.button_ 
                                "btn btn-secondary"
                                { onClick: dispatch $ Downvote comment.id }
                                "Downvote"
                            ]
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

createComment :: Int -> String -> String -> Aff Unit
createComment = API.post "create_comment_path" \call postId commenter comment -> 
  call { postId: postId, commenter, comment } >>= API.ignoreResponse

upvoteComment :: Int -> Aff Unit
upvoteComment = API.post "upvote_comment_path" \call commentId ->
  call { commentId } >>= API.ignoreResponse

downvoteComment :: Int -> Aff Unit
downvoteComment = API.post "downvote_comment_path" \call commentId ->
  call { commentId } >>= API.ignoreResponse