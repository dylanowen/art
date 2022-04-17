use bevy::input::system::exit_on_esc_system;
use bevy::prelude::*;
use rand::{thread_rng, Rng};

use wasm_bindgen::prelude::*;

use shared::pan_orbit_camera::{pan_orbit_camera, PanOrbitCamera};

const MAX_SPEED: f32 = 1.0;

const COHERENCE: f32 = 0.01;
const PERSONAL_SPACE: f32 = 2.;
const VELOCITY_FACTOR: f32 = 0.01;

#[derive(Component, Default)]
struct Boid;

#[derive(Component, Default)]
struct Velocity(Vec3);

#[wasm_bindgen(start)]
pub fn run() {
    App::new()
        .insert_resource(Msaa { samples: 4 })
        .add_plugins(DefaultPlugins)
        .add_startup_system(setup)
        .add_system(emergent_system)
        .add_system(move_system)
        .add_system(pan_orbit_camera)
        .add_system(exit_on_esc_system)
        .run();
}

fn emergent_system(
    boids: Query<Entity, With<Boid>>,
    transforms: Query<(&Transform, Entity), With<Boid>>,
    mut velocities: Query<(&mut Velocity, Entity), With<Boid>>,
) {
    let (center_sum, num_other_boids) = transforms.iter().fold(
        (Vec3::ZERO, -1),
        |(center_sum, num_boids), (transform, _)| {
            (center_sum + transform.translation, num_boids + 1)
        },
    );

    let velocity_sum = velocities
        .iter()
        .fold(Vec3::ZERO, |velocity_sum, (Velocity(velocity), _)| {
            velocity_sum + *velocity
        });

    for my_entity in boids.iter() {
        let my_position = transforms.get(my_entity).unwrap().0.translation;
        let my_velocity = velocities.get(my_entity).unwrap().0 .0;
        let mut velocity_delta = Vec3::ZERO;

        // coherence velocity
        let other_center = (center_sum - my_position) / num_other_boids as f32;
        let to_center = other_center - my_position;

        velocity_delta += to_center * COHERENCE;

        // avoidance velocity
        let mut avoidance_vector = Vec3::ZERO;
        for (transform, entity) in transforms.iter() {
            let opposite_direction = my_position - transform.translation;
            if entity != my_entity && opposite_direction.length() <= PERSONAL_SPACE {
                avoidance_vector += opposite_direction;
            }
        }

        velocity_delta += avoidance_vector;

        // matching velocity
        let other_velocities = (velocity_sum - my_velocity) / num_other_boids as f32;
        let to_other_velocities = other_velocities - my_velocity;

        velocity_delta += to_other_velocities * VELOCITY_FACTOR;

        let my_velocity = &mut velocities.get_mut(my_entity).unwrap().0 .0;
        *my_velocity += velocity_delta * 0.1;
        *my_velocity = my_velocity.clamp_length_max(MAX_SPEED);
    }
}

fn move_system(mut query: Query<(&mut Transform, &Velocity)>) {
    for (mut position, Velocity(velocity)) in query.iter_mut() {
        position.translation += *velocity;
        position.look_at(*velocity, Vec3::Z);
    }
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    let mut rng = thread_rng();
    // boids
    for x in (-10..20).step_by(4) {
        for y in (-10..20).step_by(4) {
            // let z = 0;
            for z in (-10..20).step_by(4) {
                commands
                    .spawn_bundle(PbrBundle {
                        mesh: meshes.add(Mesh::from(shape::Icosphere {
                            radius: 0.2,
                            subdivisions: 1,
                        })),
                        material: materials.add(Color::rgb(0.8, 0.7, 0.6).into()),
                        transform: Transform::from_xyz(x as f32, y as f32, z as f32),
                        ..Default::default()
                    })
                    .insert(Boid)
                    // .insert(Boid { flock: Vec::new() })
                    .insert(Velocity(
                        Vec3::new(
                            rng.gen_range(-1.0..1.0),
                            rng.gen_range(-1.0..1.0),
                            rng.gen_range(-1.0..1.0),
                        )
                        .clamp_length_max(MAX_SPEED),
                    ));
            }
        }
    }

    commands
        .spawn_bundle(PbrBundle {
            mesh: meshes.add(Mesh::from(shape::Icosphere {
                radius: 0.2,
                subdivisions: 1,
            })),
            material: materials.add(Color::rgb(0.8, 0.7, 0.6).into()),
            transform: Transform::from_xyz(1., 1., 0.),
            ..Default::default()
        })
        .insert(Boid)
        .insert(Velocity(
            Vec3::new(
                rng.gen_range(-1.0..1.0),
                rng.gen_range(-1.0..1.0),
                rng.gen_range(-1.0..1.0),
            )
            .clamp_length_max(MAX_SPEED),
        ));

    commands
        .spawn_bundle(PbrBundle {
            mesh: meshes.add(Mesh::from(shape::Icosphere {
                radius: 0.2,
                subdivisions: 1,
            })),
            material: materials.add(Color::rgb(0.8, 0.7, 0.6).into()),
            transform: Transform::from_xyz(-1., -1., 0.),
            ..Default::default()
        })
        .insert(Boid)
        .insert(Velocity(
            Vec3::new(
                rng.gen_range(-1.0..1.0),
                rng.gen_range(-1.0..1.0),
                rng.gen_range(-1.0..1.0),
            )
            .clamp_length_max(MAX_SPEED),
        ));

    // "sun"
    commands.spawn_bundle(PbrBundle {
        mesh: meshes.add(Mesh::from(shape::Icosphere {
            radius: 1.,
            subdivisions: 1,
        })),
        material: materials.add(Color::rgb(0.8, 0.7, 0.6).into()),
        transform: Transform::from_xyz(0.0, 0.5, 0.0),
        ..Default::default()
    });

    // "sun" light
    commands.spawn_bundle(PointLightBundle {
        transform: Transform::from_xyz(0., 0., 0.),
        point_light: PointLight {
            intensity: 100000.,
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
            radius: 50.,
            ..Default::default()
        });
}
