// copied from bevy::pbr
struct ClusterOffsetAndCount {
    offset: u32;
    count: u32;
};

fn unpack_offset_and_count(cluster_index: u32) -> ClusterOffsetAndCount {
    let offset_and_count = cluster_offsets_and_counts.data[cluster_index >> 2u][cluster_index & ((1u << 2u) - 1u)];
    var output: ClusterOffsetAndCount;
    // The offset is stored in the upper 24 bits
    output.offset = (offset_and_count >> 8u) & ((1u << 24u) - 1u);
    // The count is stored in the lower 8 bits
    output.count = offset_and_count & ((1u << 8u) - 1u);
    return output;
}

fn get_light_id(index: u32) -> u32 {
    // The index is correct but in cluster_light_index_lists we pack 4 u8s into a u32
    // This means the index into cluster_light_index_lists is index / 4
    let indices = cluster_light_index_lists.data[index >> 4u][(index >> 2u) & ((1u << 2u) - 1u)];
    // And index % 4 gives the sub-index of the u8 within the u32 so we shift by 8 * sub-index
    return (indices >> (8u * (index & ((1u << 2u) - 1u)))) & ((1u << 8u) - 1u);
}

fn view_z_to_z_slice(view_z: f32, is_orthographic: bool) -> u32 {
    if (is_orthographic) {
        // NOTE: view_z is correct in the orthographic case
        return u32(floor((view_z - lights.cluster_factors.z) * lights.cluster_factors.w));
    } else {
        // NOTE: had to use -view_z to make it positive else log(negative) is nan
        return min(
            u32(log(-view_z) * lights.cluster_factors.z - lights.cluster_factors.w + 1.0),
            lights.cluster_dimensions.z - 1u
        );
    }
}

fn fragment_cluster_index(frag_coord: vec2<f32>, view_z: f32, is_orthographic: bool) -> u32 {
    let xy = vec2<u32>(floor(frag_coord * lights.cluster_factors.xy));
    let z_slice = view_z_to_z_slice(view_z, is_orthographic);
    // NOTE: Restricting cluster index to avoid undefined behavior when accessing uniform buffer
    // arrays based on the cluster index.
    return min(
        (xy.y * lights.cluster_dimensions.x + xy.x) * lights.cluster_dimensions.z + z_slice,
        lights.cluster_dimensions.w - 1u
    );
}

fn point_light_offset_and_count(surface_point: vec3<f32>) -> ClusterOffsetAndCount {
    // leverage bevy's clustered forward rendering to get the relevant lights
    let is_orthographic = view.projection[3].w == 1.0;
    let view_z = dot(vec4<f32>(
        view.inverse_view[0].z,
        view.inverse_view[1].z,
        view.inverse_view[2].z,
        view.inverse_view[3].z
    ), vec4<f32>(surface_point, 1.0));
    let cluster_index = fragment_cluster_index(surface_point.xy, view_z, is_orthographic);

    return unpack_offset_and_count(cluster_index);
}