module Utils.Pusher
  ( Channel
  , ChannelName
  , Config(..)
  , EventHandler
  , EventName
  , Pusher
  , channelListener
  , eventHandler
  , init
  , trigger
  , subscribe
  , unsubscribe
  , SocketId
  , socketId
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect (Effect)
import Elmish (createElement', mkEffectFn1)
import Elmish.Foreign (class CanPassToJavaScript, class CanReceiveFromJavaScript, ValidationResult(..))
import Elmish.React.Import (ImportedReactComponent, ImportedReactComponentConstructor, EmptyProps)
import Unsafe.Coerce (unsafeCoerce)

newtype Config = Config
  { authToken :: String
  , authPath :: String
  , cluster :: String
  , key :: String
  , dev :: Nullable
    { wsHost :: String
    , wsPort :: Int
    }
  }

instance CanReceiveFromJavaScript Config where
  -- We allow the Pusher config to just pass through without checking its type.
  -- This is in order to allow hacking it with different values in dev and test
  -- environments.
  validateForeignType _ _ = Valid

-------------------------------------------------------------------------------------------

data Pusher

data Channel
instance jsChannel :: CanPassToJavaScript Channel

-- The socket ID can be used to prevent current client from receiving an event
-- they just triggered.
--
-- For example, in a chat application, the user types in a message and sends it.
-- It is immediately rendered client-side without server-side roundtrip. At the
-- same time, it’s sent to the server for persistence. Once the message is
-- broadcasted from the server, we don’t want to receive a duplicate on the
-- client that created it. When we include the current client’s socket ID,
-- Pusher omits sending an event to that client:
-- https://pusher.com/docs/channels/server_api/excluding-event-recipients
data SocketId

type ChannelName = String
type EventName = String

foreign import init :: Config -> Pusher
foreign import subscribe :: ChannelName -> Pusher -> Effect Channel
foreign import unsubscribe :: Channel -> Pusher -> Effect Unit
foreign import trigger :: forall r. Channel -> EventName -> { | r } -> Effect Unit

socketId :: Pusher -> Effect (Maybe SocketId)
socketId pusher = Nullable.toMaybe <$> socketId_ pusher

foreign import socketId_ :: Pusher -> Effect (Nullable SocketId)

-------------------------------------------------------------------------------------------

type ChannelListenerProps r =
  ( channel :: Channel
  , event :: EventName
  , onEvent :: EventHandler
  | r
  )

channelListener :: ImportedReactComponentConstructor ChannelListenerProps EmptyProps
channelListener = createElement' channelListener_
foreign import channelListener_ :: ImportedReactComponent

-------------------------------------------------------------------------------------------

data EventHandler
instance jsEventHandler :: CanPassToJavaScript EventHandler

eventHandler :: forall dta. CanReceiveFromJavaScript dta => (dta -> Effect Unit) -> EventHandler
eventHandler = unsafeCoerce <<< mkEffectFn1
