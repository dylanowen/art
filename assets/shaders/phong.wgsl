#import "shaders/bevy_utils.wgsl"

// https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_reflection_model
fn phong_lighting(
    surface_point: vec3<f32>,
    surface_normal: vec3<f32>,
    ambient_color: vec3<f32>,
    diffuse_color: vec3<f32>,
    specular_color: vec3<f32>,
    albedo: f32,
    shininess: f32
) -> vec3<f32> {
    var color = albedo * ambient_color;

    let oc = point_light_offset_and_count(surface_point);
    for (var i = oc.offset; i < oc.offset + oc.count; i = i + 1u) {
        let point_light = point_lights.data[i];

        let light_direction = point_light.position_radius.xyz - surface_point;
        let unit_light_direction = normalize(light_direction);

        // DIFFUSE LIGHT
        let lambertian = dot(unit_light_direction, surface_normal);
        if (lambertian > 0.) {
            // get the decrease in intensity of the light based on distance
            // const float attenuation = point_light.intensity / length(light_direction);
            let attenuation = 0.4;

            var light_color_contrib = diffuse_color * lambertian;

            // SPECULAR LIGHT
            // only contributes to the overall light if we can see the diffuse light

            let reflection_direction = normalize(reflect(-light_direction, surface_normal));
            let specular_angle = dot(reflection_direction, surface_normal);

            if (specular_angle > 0.) {
                let specular = pow(specular_angle, shininess);

                light_color_contrib = light_color_contrib + (specular_color * specular);
            }

            color = color + (attenuation * light_color_contrib);
        }
    }
    //for (var i = 0u; i < arrayLength(point_lights.data); i = i + 1) {
    //    let light = point_lights.data[i];
    //}

    return color;
}