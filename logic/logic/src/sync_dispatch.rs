use crate::error::any_err_to_string;
use crate::sync_handlers::*;
use protos::{Message, Service::*};
use std::{panic, thread};

macro_rules! r {
    ($e: expr) => {{
        let b: Box<dyn Message> = Box::new($e);
        b
    }};
}

pub fn dispatch_request(req: SyncRequest) -> Result<Vec<u8>, String> {
    log::debug!("serving sync request on {:?}", thread::current());

    use SyncRequest_oneof_value::*;
    let response = panic::catch_unwind(|| match req.value.expect("no sync req") {
        configure(r) => r!(handle_configure(r)),
        local_user(r) => r!(handle_local_user(r)),
        auth(r) => r!(handle_auth(r)),
    });

    response
        .map(|response| {
            let mut response_buf = Vec::with_capacity(response.compute_size() as usize + 1);
            response.write_to_vec(&mut response_buf).unwrap();
            response_buf
        })
        .map_err(any_err_to_string)
}