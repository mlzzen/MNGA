mod error;

use crate::config;
use lazy_static::lazy_static;
use std::ops::Deref;

pub use error::{CacheError, CacheResult};

lazy_static! {
    pub static ref CACHE: Cache = {
        let path = &config::CONF.get().expect("no configuration").cache_path;
        let db = sled::Config::new()
            .path(path)
            .flush_every_ms(Some(1000))
            .cache_capacity(50 * 1024 * 1024)
            .open()
            .expect("cannot open or create cache db");
        log::info!("open db at {:?}, is_empty: {}", path, db.is_empty());

        Cache::new(db)
    };
}

pub struct Cache {
    db: sled::Db,
}

impl Deref for Cache {
    type Target = sled::Db;

    fn deref(&self) -> &Self::Target {
        &self.db
    }
}

impl Cache {
    fn new(db: sled::Db) -> Self {
        Self { db }
    }

    #[allow(unused_results)]
    pub fn insert_msg<M: protobuf::Message>(&self, key: &str, msg: M) -> CacheResult<Option<M>> {
        log::info!("insert: key={}, msg={:?}", key, msg);
        let key_bytes = key.as_bytes();
        let value = msg.write_to_bytes()?;
        let last = self.db.insert(key_bytes, value)?;
        let last_msg = last.and_then(|ivec| M::parse_from_bytes(&ivec).ok());
        Ok(last_msg)
    }

    pub fn get_msg<M: protobuf::Message>(&self, key: &str) -> CacheResult<Option<M>> {
        let key_bytes = key.as_bytes();
        let value = self.db.get(key_bytes)?;
        let value_msg = value.and_then(|ivec| M::parse_from_bytes(&ivec).ok());
        log::info!("get: key={}, msg={:?}", key, value_msg);
        Ok(value_msg)
    }

    #[allow(unused_results)]
    pub fn insert_msg_async<M: protobuf::Message>(
        &self,
        key: &str,
        msg: M,
    ) -> CacheResult<Option<M>> {
        tokio::task::block_in_place(move || self.insert_msg(key, msg))
    }

    pub fn get_msg_async<M: protobuf::Message>(&self, key: &str) -> CacheResult<Option<M>> {
        tokio::task::block_in_place(move || self.get_msg(key))
    }
}
