{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell #-}
module System.Sound where
import Control.Monad.State
import Data.ECS

data SoundSystem = SoundSystem Int deriving Show
defineSystemKey ''SoundSystem

data SoundSource = SoundSource 
    { scChannel  :: Int
    , scSourceID :: Int 
    } deriving Show
defineComponentKey ''SoundSource


initSystemSound :: (HasECS s, MonadState s m) => m ()
initSystemSound = do
    registerSystem sysSound (SoundSystem 0)

tickSystemSound :: (HasECS s, MonadState s m, MonadIO m) => m ()
tickSystemSound = modifySystem sysSound $ \(SoundSystem i) -> do
    let newValue = (SoundSystem (i + 1))
    liftIO . print $ newValue
    return newValue

