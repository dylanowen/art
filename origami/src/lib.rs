use bevy::input::system::exit_on_esc_system;
use bevy::prelude::*;
use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn run() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_system(exit_on_esc_system)
        .run();
}
