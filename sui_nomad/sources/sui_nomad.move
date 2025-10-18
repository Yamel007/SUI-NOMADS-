/*
/// Module: sui_nomad
module sui_nomad::sui_nomad;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

module sui_nomads::sui_nomads;

use std::ascii;
use std::vector;
use sui::event;
use sui::object::{UID, new, id};
use sui::transfer;
use sui::tx_context::{TxContext, sender};

/// NFT structure
public struct SuiNomad has key, store {
    id: UID,
    name: ascii::String,
    description: ascii::String,
    image_url: ascii::String,
    metadata_url: ascii::String,
}

/// Event fired when minting occurs
public struct MintEvent has copy, drop, store {
    object_id: sui::object::ID,
    name: ascii::String,
}

/// Stores collection metadata and optional automated mint lists
public struct Collection has key {
    id: UID,
    metadata_list: vector<ascii::String>,
    name_list: vector<ascii::String>,
    desc_list: vector<ascii::String>,
    img_list: vector<ascii::String>,
}

/// Initialize collection with metadata and optional NFT auto lists
public fun init_collection(
    metadata_list: vector<ascii::String>,
    name_list: vector<ascii::String>,
    desc_list: vector<ascii::String>,
    img_list: vector<ascii::String>,
    ctx: &mut TxContext,
) {
    let collection = Collection {
        id: new(ctx),
        metadata_list,
        name_list,
        desc_list,
        img_list,
    };
    transfer::share_object(collection);
}

/// Mint NFT with dynamic inputs
public fun mint_nft(
    collection: &mut Collection,
    name_bytes: vector<u8>,
    desc_bytes: vector<u8>,
    img_bytes: vector<u8>,
    ctx: &mut TxContext,
) {
    let sender_addr = sender(ctx);
    let bytes = sender_addr.to_bytes();
    let first_byte = *vector::borrow(&bytes, 0);
    let idx = (first_byte as u64) % (vector::length(&collection.metadata_list) as u64);
    let metadata_url = *vector::borrow(&collection.metadata_list, idx);

    let name = ascii::string(name_bytes);
    let desc = ascii::string(desc_bytes);
    let img = ascii::string(img_bytes);

    let nft = SuiNomad {
        id: new(ctx),
        name,
        description: desc,
        image_url: img,
        metadata_url,
    };

    let obj_id = id(&nft);
    event::emit(MintEvent { object_id: obj_id, name: nft.name });

    transfer::public_transfer(nft, sender(ctx));
}

/// Mint NFT automatically from collection lists
public fun mint_random_collection_nft(collection: &mut Collection, ctx: &mut TxContext) {
    let sender_addr = sender(ctx);
    let bytes = sender_addr.to_bytes();
    let first_byte = *vector::borrow(&bytes, 0);

    let meta_idx = (first_byte as u64) % (vector::length(&collection.metadata_list) as u64);
    let name_idx = (first_byte as u64) % (vector::length(&collection.name_list) as u64);
    let desc_idx = (first_byte as u64) % (vector::length(&collection.desc_list) as u64);
    let img_idx = (first_byte as u64) % (vector::length(&collection.img_list) as u64);

    let metadata_url = *vector::borrow(&collection.metadata_list, meta_idx);
    let name = *vector::borrow(&collection.name_list, name_idx);
    let desc = *vector::borrow(&collection.desc_list, desc_idx);
    let img = *vector::borrow(&collection.img_list, img_idx);

    let nft = SuiNomad {
        id: new(ctx),
        name,
        description: desc,
        image_url: img,
        metadata_url,
    };
    let obj_id = id(&nft);
    event::emit(MintEvent { object_id: obj_id, name: nft.name });
    transfer::public_transfer(nft, sender(ctx));
}
