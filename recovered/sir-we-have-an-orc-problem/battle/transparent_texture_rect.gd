extends TextureRect

@export var cam: BattleCamera

@export var flame_tex: Texture2D
@export var flame_scale_curve_tex: CurveTexture
@export var flame_color_ramp_tex: GradientTexture1D
@export var flame_color_ramp_supporter_tex: GradientTexture1D

var rd: RenderingDevice
var framebuffer: RID

var sd_flames: GPU.SimpleDraw
var flames_draw_dispatch_buffer: RID
var update_flames_draw_dispatch_uniform_set: RID
var flame_tex_sampler: RID
var flame_tex_copy: RID
var flame_scale_curve_tex_copy: RID
var flame_color_ramp_tex_copy: RID
var flame_color_ramp_supporter_tex_copy: RID

var sd_lightnings: GPU.SimpleDraw
var lightnings_draw_dispatch_buffer: RID
var update_lightnings_draw_dispatch_uniform_set: RID

var sd_explosions: GPU.SimpleDraw
var explosions_draw_dispatch_buffer: RID
var update_explosions_draw_dispatch_uniform_set: RID


var result_texture: Texture2DRD

func _ready() -> void :
	rd = GPUSim.rd

	get_viewport().size_changed.connect(_on_resized)
	set_process(false)

func initialize() -> void :
	_init_resources()
	set_process(true)

func _exit_tree() -> void :
	GPU.rid_safe_free(rd, framebuffer)
	if result_texture:
		GPU.rid_safe_free(rd, result_texture.texture_rd_rid)
	GPU.sd_safe_free(sd_flames)
	GPU.rid_safe_free(rd, flame_tex_sampler)
	GPU.rid_safe_free(rd, flame_tex_copy)
	GPU.rid_safe_free(rd, flame_scale_curve_tex_copy)
	GPU.rid_safe_free(rd, flame_color_ramp_tex_copy)
	GPU.rid_safe_free(rd, flame_color_ramp_supporter_tex_copy)
	GPU.sd_safe_free(sd_lightnings)
	GPU.sd_safe_free(sd_explosions)


func _on_resized() -> void :
	_create_framebuffer()

func _init_resources() -> void :
	_create_framebuffer()


	flames_draw_dispatch_buffer = GPU.create_draw_dispatch_buffer(rd, "flames_draw_dispatch")

	update_flames_draw_dispatch_uniform_set = GPUSim._create_draw_dispatch_uniform_set(GPUSim.body_buffers.type_counts, flames_draw_dispatch_buffer)

	var flame_sampler_state: RDSamplerState = RDSamplerState.new()
	flame_sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	flame_sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	flame_sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	flame_tex_sampler = GPU.sampler_create(rd, "flame_tex_sampler", flame_sampler_state)

	flame_tex_copy = GPU.create_texture_copy(rd, "flame_tex_copy", flame_tex, RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB)
	flame_scale_curve_tex_copy = GPU.create_texture_copy(rd, "flame_scale_curve_tex_copy", flame_scale_curve_tex, RenderingDevice.DATA_FORMAT_R32_SFLOAT)
	var color_ramp_sourc_tex: = flame_color_ramp_supporter_tex if Options.supporter_flames_enabled else flame_color_ramp_tex
	flame_color_ramp_tex_copy = GPU.create_texture_copy(rd, "flame_color_ramp_tex_copy", color_ramp_sourc_tex, RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)

	sd_flames = GPU.SimpleDraw.new(rd, "draw_flames", load("res://shaders/rigidbody/draw_flames.glsl"), framebuffer, 
		{
			GPUSim.bindings[&"RIGIDBODY_SET"]: GPUSim.rigidbody_uniforms, 
			3: GPU.UniformsArray.new([
				GPU.create_sampler_texture_uniform(0, flame_tex_sampler, flame_tex_copy), 
				GPU.create_sampler_texture_uniform(1, flame_tex_sampler, flame_scale_curve_tex_copy), 
				GPU.create_sampler_texture_uniform(2, flame_tex_sampler, flame_color_ramp_tex_copy), 
			]), 
		}
	)
	sd_flames.draw_flags = RenderingDevice.DrawFlags.DRAW_CLEAR_ALL
	sd_flames.clear_colors = [Color(0, 0, 0, 0)]


	lightnings_draw_dispatch_buffer = GPU.create_draw_dispatch_buffer(rd, "lightnings_draw_dispatch")

	update_lightnings_draw_dispatch_uniform_set = GPUSim._create_draw_dispatch_uniform_set(GPUSim.other_resources.lightning_counts, lightnings_draw_dispatch_buffer)

	sd_lightnings = GPU.SimpleDraw.new(rd, "draw_lightnings", load("res://shaders/other/draw_lightnings.glsl"), framebuffer, 
		{
			GPUSim.bindings[&"OTHER_SET"]: GPUSim.other_uniforms, 
		}
	)


	explosions_draw_dispatch_buffer = GPU.create_draw_dispatch_buffer(rd, "explosions_draw_dispatch")

	update_explosions_draw_dispatch_uniform_set = GPUSim._create_draw_dispatch_uniform_set(GPUSim.other_resources.explosion_counts, explosions_draw_dispatch_buffer)

	sd_explosions = GPU.SimpleDraw.new(rd, "draw_explosions", load("res://shaders/other/draw_explosions.glsl"), framebuffer, 
		{
			GPUSim.bindings[&"OTHER_SET"]: GPUSim.other_uniforms, 
		}
	)

func _create_framebuffer() -> void :
	if framebuffer:
		GPU.rid_safe_free(rd, framebuffer)
	if result_texture:
		GPU.rid_safe_free(rd, result_texture.texture_rd_rid)
	var vp: Viewport = get_viewport()
	var vp_size: = Vector2i(vp.get_visible_rect().size)
	var tex_format: = RDTextureFormat.new()
	tex_format.width = vp_size.x
	tex_format.height = vp_size.y
	if vp.use_hdr_2d:
		tex_format.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	else:
		tex_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tex_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | 
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)

	var tex_view: = RDTextureView.new()
	var rd_texture: = GPU.texture_create(rd, "transparent_framebuffer_tex", tex_format, tex_view)
	result_texture = Texture2DRD.new()
	result_texture.texture_rd_rid = rd_texture
	texture = result_texture

	framebuffer = GPU.framebuffer_create(rd, "transparent_framebuffer", [rd_texture])
	assert (framebuffer)


	if sd_flames:
		sd_flames.framebuffer = framebuffer

	if sd_lightnings:
		sd_lightnings.framebuffer = framebuffer

	if sd_explosions:
		sd_explosions.framebuffer = framebuffer


func _process(_delta: float) -> void :
	GPUSim._update_draw_dispatch_buffer(update_flames_draw_dispatch_uniform_set, 4)
	GPUSim._update_draw_dispatch_buffer(update_lightnings_draw_dispatch_uniform_set, 0)
	GPUSim._update_draw_dispatch_buffer(update_explosions_draw_dispatch_uniform_set, 0)

	sd_flames.draw_indirect(flames_draw_dispatch_buffer, 0, 
		[
			GPU.PushAttribute.create_static(cam.world_to_clip_mat.to_byte_array(), 16), 
			GPUSim.push_dict[GPUSim.PUSH_WORLD_SIZE], 
			GPUSim.push_dict[GPUSim.PUSH_TIME_MS], 
			GPUSim.push_dict[GPUSim.PUSH_TIME_RENDER_MS], 
			GPUSim.push_dict[GPUSim.PUSH_FLAME_LIFETIME]
		])

	sd_lightnings.draw_indirect(lightnings_draw_dispatch_buffer, 0, 
		[
			GPU.PushAttribute.create_static(cam.world_to_clip_mat.to_byte_array(), 16), 
			GPUSim.push_dict[GPUSim.PUSH_WORLD_SIZE], 
			GPUSim.push_dict[GPUSim.PUSH_TIME_MS], 
			GPUSim.push_dict[GPUSim.PUSH_TIME_RENDER_MS]
		])

	sd_explosions.draw_indirect(explosions_draw_dispatch_buffer, 0, 
		[
			GPU.PushAttribute.create_static(cam.world_to_clip_mat.to_byte_array(), 16), 
			GPUSim.push_dict[GPUSim.PUSH_WORLD_SIZE], 
			GPUSim.push_dict[GPUSim.PUSH_TIME_MS], 
			GPUSim.push_dict[GPUSim.PUSH_TIME_RENDER_MS]
		])
