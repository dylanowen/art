#import bevy_pbr::mesh_view_bind_group
#import bevy_pbr::mesh_struct

#import "shaders/sdf/mandelbulb.wgsl"
#import "shaders/bevy_utils.wgsl"
#import "shaders/phong.wgsl"

[[group(1), binding(0)]]
var<uniform> mesh: Mesh;

struct Vertex {
    [[location(0)]] position: vec3<f32>;
    [[location(1)]] normal: vec3<f32>;
    [[location(2)]] uv: vec2<f32>;
};

struct VertexOutput {
    [[builtin(position)]] gpu_position: vec4<f32>;
    [[location(0)]] world_position: vec3<f32>;
    [[location(1)]] ray_position: vec3<f32>;
    [[location(2)]] max_distance: f32;
};

[[stage(vertex)]]
fn vertex(vertex: Vertex) -> VertexOutput {
    let world_position = mesh.model * vec4<f32>(vertex.position, 1.0);

    var out: VertexOutput;
    out.gpu_position = view.view_proj * world_position;
    out.world_position = world_position.xyz;
    // we're assuming our SDF exists at 0, where our vertecies exist so don't use our mesh transform
    out.ray_position = vertex.position;
    // create a vector to the far plane and get the distance from our near plane
    out.max_distance = distance(world_position, view.inverse_view * vec4<f32>(0.0, 0.0, 1.0, 1.0));

    return out;
}



struct Time {
    time_since_startup: f32;
};

[[group(2), binding(0)]]
var<uniform> time: Time;

let MAX_MARCHING_STEPS: u32 = 150u;
let EPSILON: f32 = 0.001;

fn distance_estimator(point: vec3<f32>) -> f32 {
    //return length(point) - 0.15;
    return mandelbulb_de(point, time.time_since_startup / 8.0);
}

// TODO distance_estimator should be in module scope https://gpuweb.github.io/gpuweb/wgsl/#module-scope
// but since it isn't, abuse the preprocessor
#import "shaders/sdf/lib.wgsl"

[[stage(fragment)]]
fn fragment(in: VertexOutput) -> [[location(0)]] vec4<f32> {
    // interpolation doesn't work across vectors like this since it would change our projection, so calculate here
    let ray = normalize(in.world_position - view.world_position);
    let march_result = ray_march(in.ray_position, ray, MAX_MARCHING_STEPS, EPSILON, in.max_distance);

    if (march_result.collided) {
        let normal = estimate_normal(march_result.point, EPSILON);
        let color = phong_lighting(
            march_result.point,
            normal,
            lights.ambient_color.xyz,
            vec3<f32>(0.0, 0.0, 1.0),
            vec3<f32>(f32(march_result.steps) / f32(MAX_MARCHING_STEPS), 0., 0.2),
            0.5,
            10.0
        );

        return vec4<f32>(color, 1.0);
    }
    else {
        return vec4<f32>(0.0);
    }

}