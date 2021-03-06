{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Data.ECS.Types where

import Data.ECS.Vault (Vault)

import Data.HashMap.Strict (HashMap)
import Data.HashSet (HashSet)
import GHC.Word

import Control.Lens.Extra
import Control.Monad.State
import Control.Monad.Reader
import Control.Monad.Trans.Control

import Data.Yaml

type Map = HashMap
type Set = HashSet

type EntityID = Word32

type EntityMap a = Map EntityID a

type ComponentName = String
type EntityName = String

type ECSMonad = StateT ECS IO
type EntityMonad = ReaderT EntityID ECSMonad

inEntity :: EntityID -> ReaderT EntityID m a -> m a
inEntity entityID action = runReaderT action entityID

newtype Components = Components { _unComponents :: Vault } deriving Monoid

data ECS = ECS
    { _wldSystems            :: Vault
    , _wldComponents         :: Components
    , _wldComponentLibrary   :: Map ComponentName ComponentInterface
    , _wldPersistentEntities :: Set EntityID
    }

newECS :: ECS
newECS = ECS mempty mempty mempty mempty

data ComponentInterface = ComponentInterface
    { ciRemoveComponent  :: forall m. (MonadReader EntityID m, MonadState ECS m, MonadIO m) => (m ())
    , ciExtractComponent :: forall m. (MonadReader EntityID m, MonadState ECS m, MonadIO m) => Maybe (m (Maybe Value))
    , ciRestoreComponent :: forall m. (MonadReader EntityID m, MonadState ECS m, MonadIO m, MonadBaseControl IO m) => Maybe (Value -> m ())
    , ciDeriveComponent  :: forall m. (MonadReader EntityID m, MonadState ECS m, MonadIO m, MonadBaseControl IO m) => Maybe (m ())
    }

-- We can't use makeClassy to define the HasECS class and lenses,
-- since the ComponentInterface and ECS types have a circular dependency,
-- meaning either ComponentInterface can't see the generated "HasECS" class
-- or ECS can't see the ComponentInterface type.
-- This just means we have to prefix our lenses with "ecs" internally, but that's not so bad.
class HasECS s where
    ecs :: Lens' s ECS

instance HasECS ECS where
    ecs = id

makeLenses ''ECS
makeLenses ''Components

class HasComponents s where
    components :: Lens' s Components

instance HasComponents ECS where
    components = wldComponents

instance HasComponents Components where
    components = id
