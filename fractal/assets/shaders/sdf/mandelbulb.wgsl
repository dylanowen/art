let BAILOUT: f32 = 4.0;

fn mandelbulb_de(position: vec3<f32>, power: f32) -> f32 {
    var z = position;
    var dr = 1.0;
    var r = 0.0;

    for (var i = 0u; i < 20u; i = i + 1u) {
        r = length(z);
        if (r > BAILOUT) {
            break;
        }

        // convert to polar coordinates
        var theta = acos(z.z / r);
        var phi = atan2(z.y, z.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;

        // scale and rotate the point
        let zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;


        // convert back to cartesian coordinates
        z = zr * vec3<f32>(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z = z + position;
    }

    return 0.5 * log(r) * r / dr;
}