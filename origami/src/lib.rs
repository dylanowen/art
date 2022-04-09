use bevy::input::system::exit_on_esc_system;
use bevy::prelude::*;
use bevy::render::mesh::Indices;
use bevy::render::render_resource::PrimitiveTopology;
use shared::pan_orbit_camera::{pan_orbit_camera, PanOrbitCamera};
use std::f32::consts::{PI, TAU};
use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn run() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_startup_system(setup)
        .add_system(pan_orbit_camera)
        .add_system(exit_on_esc_system)
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    // let model = OrigamiModel {
    //     positions: vec![[0., 0.], [1., 1.], [1., -1.], [-1., -1.], [-1., 1.]],
    //     planes: vec![
    //         OrigamiPlane {
    //             indices: vec![0, 1, 4],
    //         },
    //         OrigamiPlane {
    //             indices: vec![0, 2, 1],
    //         },
    //         OrigamiPlane {
    //             indices: vec![0, 3, 2],
    //         },
    //         OrigamiPlane {
    //             indices: vec![0, 4, 3],
    //         },
    //     ],
    // };
    let model = OrigamiModel {
        positions: vec![[0., 0.], [1., 1.], [1., -1.], [-1., -1.], [-1., 1.]],
        planes: PlaneNode {
            plane: OrigamiPlane {
                angle: 0.,
                indices: vec![0, 1, 4],
            },
            children: vec![
                PlaneNode {
                    plane: OrigamiPlane {
                        angle: PI,
                        indices: vec![0, 2, 1],
                    },
                    children: vec![PlaneNode {
                        plane: OrigamiPlane {
                            angle: PI,
                            indices: vec![0, 3, 2],
                        },
                        children: vec![],
                    }],
                },
                PlaneNode {
                    plane: OrigamiPlane {
                        angle: PI,
                        indices: vec![0, 4, 3],
                    },
                    children: vec![],
                },
            ],
        },
    };

    commands.spawn_bundle(PbrBundle {
        mesh: meshes.add(model.mesh()),
        material: materials.add(Color::rgb(0.8, 0.3, 0.3).into()),
        ..Default::default()
    });

    // red point light
    commands.spawn_bundle(PointLightBundle {
        // transform: Transform::from_xyz(5.0, 8.0, 2.0),
        transform: Transform::from_xyz(1.0, 2.0, 0.0),
        point_light: PointLight {
            intensity: 1600.0, // lumens - roughly a 100W non-halogen incandescent bulb
            color: Color::WHITE,
            shadows_enabled: false,
            ..Default::default()
        },
        ..Default::default()
    });

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

struct OrigamiModel {
    positions: Vec<[f32; 2]>,
    planes: PlaneNode,
}

struct PlaneNode {
    plane: OrigamiPlane,
    children: Vec<PlaneNode>,
}

struct OrigamiPlane {
    angle: f32,

    indices: Vec<u16>,
}

impl OrigamiModel {
    pub fn mesh(&self) -> Mesh {
        let intermediate = 0.5;

        let mut mesh = Mesh::new(PrimitiveTopology::TriangleList);
        mesh.set_attribute(
            Mesh::ATTRIBUTE_POSITION,
            self.positions
                .iter()
                .map(|&[x, y]| [x, y, 0.])
                .collect::<Vec<_>>(),
        );
        mesh.set_attribute(
            Mesh::ATTRIBUTE_NORMAL,
            vec![[0., 0., 1.]; self.positions.len()],
        );
        mesh.set_attribute(Mesh::ATTRIBUTE_UV_0, vec![[0., 0.]; self.positions.len()]);
        mesh.set_indices(Some(Indices::U16(
            self.planes
                .iter()
                .flat_map(|plane| plane.indices.iter().copied())
                .collect(),
        )));

        mesh
    }

    fn fold(
        &self,
        node: &PlaneNode,
        intermediate: f32,
        positions: &mut Vec<[f32; 3]>,
        folded: &mut Vec<bool>,
    ) -> Vec<[f32; 3]> {
        todo!()
    }
}
