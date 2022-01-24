use bevy::input::system::exit_on_esc_system;
use bevy::prelude::*;
use wasm_bindgen::prelude::*;

use pan_orbit_camera::pan_orbit_camera;

use crate::fractal_plugin::{FractalMaterial, FractalPlugin};
use crate::pan_orbit_camera::PanOrbitCamera;

mod fractal_plugin;
mod pan_orbit_camera;

#[wasm_bindgen(start)]
pub fn run() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugin(FractalPlugin)
        .add_startup_system(setup)
        .add_system(pan_orbit_camera)
        .add_system(exit_on_esc_system)
        .run();
}

fn setup(mut commands: Commands, mut meshes: ResMut<Assets<Mesh>>) {
    commands.spawn().insert_bundle((
        meshes.add(Mesh::from(shape::Cube { size: 2.0 })),
        // Transform::from_xyz(0.5, 0., 0.),
        Transform::default(),
        GlobalTransform::default(),
        FractalMaterial,
        Visibility::default(),
        ComputedVisibility::default(),
    ));

    // camera
    commands
        .spawn_bundle(PerspectiveCameraBundle {
            transform: Transform::from_xyz(-2.0, 2.5, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
            ..Default::default()
        })
        .insert(PanOrbitCamera {
            radius: 2.,
            ..Default::default()
        });
}
