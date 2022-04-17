// fn distance_estimator(point: vec3<f32>) -> f32;

struct MarchResult {
    collided: bool;
    point: vec3<f32>;
    distance: f32;
    steps: u32;
};

// https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
fn estimate_normal(point: vec3<f32>, epsilon: f32) -> vec3<f32> {
    let estimated_normal = vec3<f32>(
        distance_estimator(vec3<f32>(point.x + epsilon, point.y, point.z)) - distance_estimator(vec3<f32>(point.x - epsilon, point.y, point.z)),
        distance_estimator(vec3<f32>(point.x, point.y + epsilon, point.z)) - distance_estimator(vec3<f32>(point.x, point.y - epsilon, point.z)),
        distance_estimator(vec3<f32>(point.x, point.y, point.z + epsilon)) - distance_estimator(vec3<f32>(point.x, point.y, point.z - epsilon))
    );

    return normalize(estimated_normal);
}

fn ray_march(
    point: vec3<f32>,
    unit_ray: vec3<f32>,
    max_marching_steps: u32,
    epsilon: f32,
    max_distance: f32
) -> MarchResult {
    var march_result: MarchResult;
    march_result.collided = false;
    march_result.point = point;
    march_result.distance = 0.0;
    march_result.steps = 0u;

    for (; march_result.steps < max_marching_steps; march_result.steps = march_result.steps + 1u) {
        let estimated_distance = distance_estimator(march_result.point);
        march_result.distance = march_result.distance + estimated_distance;
        march_result.point = march_result.point + (unit_ray * estimated_distance);

        // if we're close enough break out
        if (estimated_distance < epsilon) {
            march_result.collided = true;
            break;
        }
        else if (march_result.distance > max_distance) {
            // we've marched too far
            break;
        }
    }

    return march_result;
}