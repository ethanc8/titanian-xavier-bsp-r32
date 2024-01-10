/*
 * Copyright © 2011 Benjamin Franzke
 * Copyright © 2010 Intel Corporation
 * Copyright © 2014 Collabora Ltd.
 * Copyright © 2020, NVIDIA CORPORATION.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <unistd.h>
#include <sys/mman.h>
#include <signal.h>
#include <fcntl.h>
#include <getopt.h>
#include <errno.h>

#include <xf86drm.h>
#include <drm_fourcc.h>
#include <tegra_drm.h>
#include <fullscreen-shell-unstable-v1-client-protocol.h>
#include <xdg-shell-client-protocol.h>
#include <linux-dmabuf-unstable-v1-client-protocol.h>
#include <nvbuf_utils.h>
#include <gbm.h>

#ifndef DRM_FORMAT_MOD_LINEAR
#define DRM_FORMAT_MOD_LINEAR 0
#endif

#define CHECK(expr) \
	do { \
		int ret = (expr); \
		if (ret != 0) { \
			if (errno == 0) { \
				fprintf(stderr,"Returned error code: %d\n",ret); \
			} else { \
				fprintf(stderr,"Returned error code: %d\n%s\n", \
					ret,strerror(errno)); \
			} \
			exit(1); \
		} \
	} while (0)

struct buffer;

/* Possible options that affect the displayed image */
#define OPT_Y_INVERTED 1  /* contents has y axis inverted */
#define OPT_IMMEDIATE  2  /* create wl_buffer immediately */
#define OPT_USE_GBM    3 /* use gmb buffer instead of nvbuf */

#define NUM_BUFFERS 3
#define MAX_PLANES 3

#define ALIGN(v, a) ((v + a - 1) & ~(a - 1))

const struct drm_format_info {
	uint32_t drm_format;
	int num_planes;
	struct {
		int w;
		int h;
		int bpp;
	} planes[MAX_PLANES];
} drm_formats[] = {
	{DRM_FORMAT_XRGB8888, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_ABGR8888, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_ARGB2101010, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_TEGRA_ARGB2101010_709, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_TEGRA_ARGB2101010_2020, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_ABGR2101010, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_TEGRA_ABGR2101010_709, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_TEGRA_ABGR2101010_2020, 1, {{1, 1, 32}, {0, 0, 0}, {0, 0, 0}}},
	{DRM_FORMAT_NV12,     2, {{1, 1, 8}, {2, 2, 16}, {0, 0, 0}}},
	{DRM_FORMAT_NV21,     2, {{1, 1, 8}, {2, 2, 16}, {0, 0, 0}}},
	{DRM_FORMAT_NV16,     2, {{1, 1, 8}, {2, 1, 16}, {0, 0, 0}}},
	{DRM_FORMAT_NV24,     2, {{1, 1, 8}, {1, 1, 16}, {0, 0, 0}}},
	{DRM_FORMAT_P010,     2, {{1, 1, 16}, {2, 2, 32}, {0, 0, 0}}},
	{DRM_FORMAT_TEGRA_P010_709, 2, {{1, 1, 16}, {2, 2, 32}, {0, 0, 0}}},
	{DRM_FORMAT_TEGRA_P010_2020, 2, {{1, 1, 16}, {2, 2, 32}, {0, 0, 0}}},
	{DRM_FORMAT_YUV420,     3, {{1, 1, 8}, {2, 2, 8}, {2, 2, 8}}},
	{DRM_FORMAT_YVU420,     3, {{1, 1, 8}, {2, 2, 8}, {2, 2, 8}}},
	{DRM_FORMAT_YUV444,     3, {{1, 1, 8}, {1, 1, 8}, {1, 1, 8}}},
};

struct display {
	struct wl_display *display;
	struct wl_registry *registry;
	struct wl_compositor *compositor;
	struct xdg_wm_base *wm_base;
	struct zwp_fullscreen_shell_v1 *fshell;
	struct zwp_linux_dmabuf_v1 *dmabuf;
	int req_dmabuf_immediate;
	uint64_t *modifiers;
	int modifiers_count;
	int drm_fd;
	struct gbm_device *gbm;
};

struct drm_dumb_bo {
	uint32_t handle;int fd;
	int width;
	int height;
	int pitch;
	int offset;
	uint8_t* data;
	size_t size;
	void *gbo_mapping;
};

struct buffer {
	struct wl_buffer *buffer;
	int busy;

	struct drm_device *dev;
	int drm_fd;
	struct gbm_bo *gbm_bo;
	void *gbm_bo_data;

	int width;
	int height;
	int format;

	struct drm_dumb_bo bo;
	int num_planes;
};

struct window {
	struct display *display;
	int width, height;
	struct buffer *buffers;
	struct wl_surface *surface;
	struct xdg_surface *xdg_surface;
	struct xdg_toplevel *xdg_toplevel;
	struct wl_callback *callback;
	bool initialized;
	bool wait_for_configure;
};

static int running = 1;
static bool use_gbm = false;

static void
redraw(void *data, struct wl_callback *callback, uint32_t time);

static int get_format_info(unsigned int drm_format,
			   struct drm_format_info *info)
{
	int i;
	int format_info_count = sizeof(drm_formats) / sizeof(drm_formats[0]);

	if (use_gbm) {
		// formats not supported by GBM
		switch(drm_format) {
		case DRM_FORMAT_TEGRA_ARGB2101010_709:
		case DRM_FORMAT_TEGRA_ARGB2101010_2020:
		case DRM_FORMAT_TEGRA_ABGR2101010_709:
		case DRM_FORMAT_TEGRA_ABGR2101010_2020:
		case DRM_FORMAT_NV24:
		case DRM_FORMAT_P010:
		case DRM_FORMAT_TEGRA_P010_709:
		case DRM_FORMAT_TEGRA_P010_2020:
			return 0;
		}
	}
	for (i = 0; i < format_info_count; i++) {
		if (drm_format == drm_formats[i].drm_format) {
			*info = drm_formats[i];
			return 1;
		}
	}
	return 0;
}

static void
buffer_release(void *data, struct wl_buffer *buffer)
{
	struct buffer *mybuf = data;

	mybuf->busy = 0;
}

static const struct wl_buffer_listener buffer_listener = {
	buffer_release
};

static void calculateRGB(int x, int y, int width, int height, int *r,int *g, 
			 int *b, int *a) {

	int R = 0, G = 255, B = 0;
	// Top-Bottom Gradient
	float f = 1.0f - (float)y/height;
	*r = (int)(f * R);
	*g = (int)(f * G);
	*b = (int)(f * B);

	// Alpha Left-Right Gradient
	*a = (int)(255 - (255 * ((float)x/width)));

	// Red grid
	if (!((x % 100)/2) || !((y % 100)/2)) {
		*r = 255;
	}

	// Blue X
	if (abs(abs(width / 2 - x) - abs(height / 2 - y)) < 10) {
		*b = 255;
	}

	// White Border
	if (x < 10 || y < 10 || x > width-10 || y > height-10) {
		*r = *g = *b = *a = 255;
	}
}

static void mapBuffer(int *height, int *width, struct buffer *buf,
		      int plane, NvBufferParams nvbuf_params) {

	*height = nvbuf_params.height[plane];
	*width = nvbuf_params.width[plane];
	CHECK(NvBufferMemMap (buf->bo.fd, plane, NvBufferMem_Write,
			      (void **)(&buf->bo.data)));
	assert(buf->bo.data);
}

static void write_pixel_RGB30(struct buffer *buf, int off,
                              uint16_t a, uint16_t b, uint16_t c, uint16_t d) {

	b *= 4;
	c *= 4;
	d *= 4;

	b <<= 6;
	c <<= 6;
	d <<= 6;

	buf->bo.data[off] = (d>>6);

	buf->bo.data[off + 1] = 0x03 & (d>>14);
	buf->bo.data[off + 1] |= 0xfc & (c>>4);

	buf->bo.data[off + 2] = 0x0f & (c>>12);
	buf->bo.data[off + 2] |= 0xf0 & (b>>2);

	buf->bo.data[off + 3] = 0x3f & (b>>10);
	buf->bo.data[off + 3] |= 0xc0;
}

static void
reorder_color_components(int format, int r, int g, int b, int a, int orderedComponent[4])
{
    switch (format) {
	case DRM_FORMAT_XRGB8888:
	case DRM_FORMAT_ARGB8888:
		orderedComponent[0] = b;
		orderedComponent[1] = g;
		orderedComponent[2] = r;
		orderedComponent[3] = a;
		break;
	case DRM_FORMAT_ABGR8888:
	case DRM_FORMAT_XBGR8888:
		orderedComponent[0] = r;
		orderedComponent[1] = g;
		orderedComponent[2] = b;
		orderedComponent[3] = a;
		break;
	case DRM_FORMAT_RGBA8888:
	case DRM_FORMAT_RGBX8888:
		orderedComponent[0] = a;
		orderedComponent[1] = b;
		orderedComponent[2] = g;
		orderedComponent[3] = r;
		break;
	case DRM_FORMAT_BGRA8888:
	case DRM_FORMAT_BGRX8888:
		orderedComponent[0] = a;
		orderedComponent[1] = r;
		orderedComponent[2] = g;
		orderedComponent[3] = b;
		break;
    }
}
static void
fill_content(struct buffer *buf, NvBufferParams nvbuf_params,
	     struct drm_format_info format_info)
{
	int x = 0, y = 0, height, width;
	int r, g, b, a, off;
	uint32_t stride;

	// Draw X pattern
	switch (buf->format) {
		case DRM_FORMAT_NV12:
		case DRM_FORMAT_NV16:
		case DRM_FORMAT_NV24:
		case DRM_FORMAT_NV21:
			// Y plane
			if (use_gbm) {
				height = nvbuf_params.height[0];
				width = nvbuf_params.width[0];
				buf->bo.data = gbm_bo_map(buf->gbm_bo, x, y, width, height, GBM_BO_TRANSFER_READ_WRITE, &stride, &buf->bo.gbo_mapping);
			} else {
				mapBuffer(&height, &width, buf, 0, nvbuf_params);
			}
			for (y = 0; y < height; ++y) {
				for (x = 0; x < width; ++x) {
					calculateRGB(x, y, width, height, &r, &g, &b, &a);
					int Y = (int)(r *  .299000 + g *  .587000 + b *  .114000);
					off = use_gbm ? gbm_bo_get_offset(buf->gbm_bo, 0) : 0;
					off += nvbuf_params.pitch[0] * y + x;
					buf->bo.data[off] = Y;
				}
			}
			if (!use_gbm) {
				CHECK(NvBufferMemSyncForCpu (buf->bo.fd, 0,
							     (void **)(&buf->bo.data)));
				// UV plane
				mapBuffer(&height, &width, buf, 1, nvbuf_params);
			} else {
				height = height / 2;
				width = width / 2;
			}
			for (y = 0; y < height; y++){
				for (x = 0; x < width;x++){
					calculateRGB(x * format_info.planes[1].w,
						     y * format_info.planes[1].h,
						     width * format_info.planes[1].w,
						     height * format_info.planes[1].h,
						     &r, &g, &b, &a);
					int U = (int)(r * -.168736 + g * -.331264 + b *  .500000 + 128);
					int V = (int)(r *  .500000 + g * -.418688 + b * -.081312 + 128);
					off = use_gbm ? gbm_bo_get_offset(buf->gbm_bo, 1) : 0;
					off += nvbuf_params.pitch[1] * y + (x * format_info.planes[1].bpp / 8);
					if (buf->format == DRM_FORMAT_NV21) {
						buf->bo.data[off] = V;
						buf->bo.data[off+1] = U;
					} else {
						buf->bo.data[off] = U;
						buf->bo.data[off+1] = V;
					}
				}
			}
			if (!use_gbm)
				NvBufferMemSyncForCpu (buf->bo.fd, 1,
						       (void **)(&buf->bo.data));

			break;

		case DRM_FORMAT_XRGB8888:
		case DRM_FORMAT_ABGR8888:
			if (use_gbm) {
				height = nvbuf_params.height[0];
				width = nvbuf_params.width[0];
				buf->bo.data = gbm_bo_map(buf->gbm_bo, x, y, width, height, GBM_BO_TRANSFER_READ_WRITE, &stride, &buf->bo.gbo_mapping);
			} else {
				mapBuffer(&height, &width, buf, 0, nvbuf_params);
			}
			for (y = 0; y < height; y++) {
				for (x = 0; x < width; x++) {
					calculateRGB(x, y, width, height, &r, &g, &b, &a);
					off = use_gbm ? gbm_bo_get_offset(buf->gbm_bo, 0) : 0;
					off = nvbuf_params.pitch[0] * y + x*4;
					int orderedComponent[4] = {0};
					reorder_color_components(buf->format, r, g, b, a, orderedComponent);
					for (int i = 0; i < 4; i++)
						buf->bo.data[off + i] = orderedComponent[i];
				}
			}
			if (!use_gbm)
				CHECK(NvBufferMemSyncForCpu (buf->bo.fd, 0, (void **)(&buf->bo.data)));
			break;

		case DRM_FORMAT_P010:
		case DRM_FORMAT_TEGRA_P010_709:
		case DRM_FORMAT_TEGRA_P010_2020:
			// Y plane
			mapBuffer(&height, &width, buf, 0, nvbuf_params);
			for (y = 0; y < height; y++) {
				for (x = 0; x< width; x++) {
					calculateRGB(x, y, width, height, &r, &g, &b, &a);
					int Y = (int)(r *  .299000 + g *  .587000 + b *  .114000);
					Y *= 4;
					Y <<= 6;

					assert(sizeof(buf->bo.data[0]) * 2 == format_info.planes[0].bpp / 8);
					off = nvbuf_params.pitch[0] * y + x * (format_info.planes[0].bpp / 8);
					buf->bo.data[off] = Y & 0x00ff;
					buf->bo.data[off+1] = Y >> 8;
				}
			}
			CHECK(NvBufferMemSyncForCpu (buf->bo.fd, 0,
						     (void **)(&buf->bo.data)));

			// UV plane
			mapBuffer(&height, &width, buf, 1, nvbuf_params);
			for (y = 0; y < height; y++){
				for (x = 0; x < width;x++){
					calculateRGB(x * format_info.planes[1].w,
						     y * format_info.planes[1].h,
						     width * format_info.planes[1].w,
						     height * format_info.planes[1].h,
						     &r, &g, &b, &a);
					int U = (int)(r * -.168736 + g * -.331264 + b *  .500000 + 128);
					int V = (int)(r *  .500000 + g * -.418688 + b * -.081312 + 128);

					U *= 4;
					V *= 4;

					U <<= 6;
					V <<= 6;

					off = nvbuf_params.pitch[1] * y + (x * format_info.planes[1].bpp / 8);
					buf->bo.data[off] = U & 0x00ff;
					buf->bo.data[off+1] = U >> 8;
					buf->bo.data[off+2] = V & 0x00ff;
					buf->bo.data[off+3] = V >> 8;
				}
			}
			NvBufferMemSyncForCpu (buf->bo.fd, 1,
					       (void **)(&buf->bo.data));

			break;
		case DRM_FORMAT_ARGB2101010:
		case DRM_FORMAT_TEGRA_ARGB2101010_709:
		case DRM_FORMAT_TEGRA_ARGB2101010_2020:
			mapBuffer(&height, &width, buf, 0, nvbuf_params);
			for (y = 0; y < height; y++) {
				for (x = 0; x < width; x++) {
					calculateRGB(x, y, width, height, &r, &g, &b, &a);
					off = nvbuf_params.pitch[0] * y + x*4;
					write_pixel_RGB30(buf, off, a, r, g, b);
				}
			}
			CHECK(NvBufferMemSyncForCpu (buf->bo.fd, 0, (void **)(&buf->bo.data)));
			break;

		case DRM_FORMAT_ABGR2101010:
		case DRM_FORMAT_TEGRA_ABGR2101010_709:
		case DRM_FORMAT_TEGRA_ABGR2101010_2020:
			mapBuffer(&height, &width, buf, 0, nvbuf_params);
			for (y = 0; y < height; y++) {
				for (x = 0; x < width; x++) {
					calculateRGB(x, y, width, height, &r, &g, &b, &a);
					off = nvbuf_params.pitch[0] * y + x*4;
					write_pixel_RGB30(buf, off, a, b, g, r);
				}
			}
			CHECK(NvBufferMemSyncForCpu (buf->bo.fd, 0, (void **)(&buf->bo.data)));
			break;
		case DRM_FORMAT_YUV420:
		case DRM_FORMAT_YVU420:
		case DRM_FORMAT_YUV444:
			for (int planeIdx = 0; planeIdx < 3; planeIdx++) {
				mapBuffer(&height, &width, buf, planeIdx, nvbuf_params);
				for (y = 0; y < height; ++y) {
					for (x = 0; x < width; ++x) {
						calculateRGB(x * format_info.planes[planeIdx].w,
							     y * format_info.planes[planeIdx].h,
							     width * format_info.planes[planeIdx].w,
							     height * format_info.planes[planeIdx].h,
							     &r, &g, &b, &a);
						int componentYUV = 0;
						// Y
						if (planeIdx == 0)
							componentYUV = (int)(r *  .299000 + g *  .587000 + b *  .114000);
						// U/V
						else if (planeIdx == 1) {
							if (buf->format == DRM_FORMAT_YVU420)
								componentYUV = (int)(r *  .500000 + g * -.418688 + b * -.081312 + 128);
							else
								componentYUV = (int)(r * -.168736 + g * -.331264 + b *  .500000 + 128);
						}
						// V/U
						else {
							if (buf->format == DRM_FORMAT_YVU420)
								componentYUV = (int)(r * -.168736 + g * -.331264 + b *  .500000 + 128);
							else
								componentYUV = (int)(r *  .500000 + g * -.418688 + b * -.081312 + 128);
						}

						off = nvbuf_params.pitch[planeIdx] * y + x;
						buf->bo.data[off] = componentYUV;
					}
				}
				CHECK(NvBufferMemSyncForCpu (buf->bo.fd, 0,
								(void **)(&buf->bo.data)));
			}
			break;
	}
}

static void
create_succeeded(void *data,
		 struct zwp_linux_buffer_params_v1 *params,
		 struct wl_buffer *new_buffer)
{
	struct buffer *buffer = data;

	buffer->buffer = new_buffer;
	wl_buffer_add_listener(buffer->buffer, &buffer_listener, buffer);

	zwp_linux_buffer_params_v1_destroy(params);
}

static void
create_failed(void *data, struct zwp_linux_buffer_params_v1 *params)
{
	struct buffer *buffer = data;

	buffer->buffer = NULL;
	running = 0;

	zwp_linux_buffer_params_v1_destroy(params);

	fprintf(stderr, "Error: zwp_linux_buffer_params.create failed.\n");
}

static const struct zwp_linux_buffer_params_v1_listener params_listener = {
	create_succeeded,
	create_failed
};

static void
destroy_dmabuf_buffer(int drm_fd, struct buffer *buffer)
{
	int i;

	if (!use_gbm) {
		for (i = 0; i < buffer->num_planes; i++) {
			CHECK(NvBufferMemUnMap(buffer->bo.fd, i, (void **)(buffer->bo.data)));
		}
		NvBufferDestroy (buffer->bo.fd);
	} else {
		gbm_bo_unmap(buffer->gbm_bo, buffer->bo.gbo_mapping);
		gbm_bo_destroy(buffer->gbm_bo);
	}
}

static int
create_dmabuf_buffer(struct display *display, struct buffer *buffer,
		     int width, int height, int format, uint32_t opts)
{
	struct zwp_linux_buffer_params_v1 *params;
	uint64_t modifier = DRM_FORMAT_MOD_LINEAR;
	uint32_t flags = 0;
	struct drm_format_info format_info;
	int i;
	NvBufferParams nvbuf_params;
	uint32_t colorFormat;

	memset(&format_info, 0, sizeof(format_info));
	if (!get_format_info(format, &format_info))
		assert(!"buffer format not supported\n");

	switch (format) {
		case DRM_FORMAT_NV12:
			colorFormat = use_gbm ? GBM_FORMAT_NV12 : NvBufferColorFormat_NV12;
			break;
		case DRM_FORMAT_NV21:
			colorFormat = NvBufferColorFormat_NV21;
			break;
		case DRM_FORMAT_NV16:
			colorFormat = use_gbm ? GBM_FORMAT_NV16 : NvBufferColorFormat_NV16;
			break;
		case DRM_FORMAT_NV24:
			colorFormat = NvBufferColorFormat_NV24;
			break;
		case DRM_FORMAT_P010:
			colorFormat = NvBufferColorFormat_NV12_10LE;
			break;
		case DRM_FORMAT_TEGRA_P010_709:
			colorFormat = NvBufferColorFormat_NV12_10LE_709;
			break;
		case DRM_FORMAT_TEGRA_P010_2020:
			colorFormat = NvBufferColorFormat_NV12_10LE_2020;
			break;
		case DRM_FORMAT_ARGB2101010:
			colorFormat = NvBufferColorFormat_BGRA_10_10_10_2_709;
			break;
		case DRM_FORMAT_TEGRA_ARGB2101010_709:
			colorFormat = NvBufferColorFormat_BGRA_10_10_10_2_709;
			break;
		case DRM_FORMAT_TEGRA_ARGB2101010_2020:
			colorFormat = NvBufferColorFormat_BGRA_10_10_10_2_2020;
			break;
		case DRM_FORMAT_ABGR2101010:
			colorFormat = NvBufferColorFormat_RGBA_10_10_10_2_709;
			break;
		case DRM_FORMAT_TEGRA_ABGR2101010_709:
			colorFormat = NvBufferColorFormat_RGBA_10_10_10_2_709;
			break;
		case DRM_FORMAT_TEGRA_ABGR2101010_2020:
			colorFormat = NvBufferColorFormat_RGBA_10_10_10_2_2020;
			break;
		case DRM_FORMAT_YUV420:
			colorFormat = NvBufferColorFormat_YUV420;
			break;
		case DRM_FORMAT_YVU420:
			colorFormat = NvBufferColorFormat_YVU420;
			break;
		case DRM_FORMAT_YUV444:
			colorFormat = NvBufferColorFormat_YUV444;
			break;
		case DRM_FORMAT_ABGR8888:
			colorFormat = NvBufferColorFormat_ABGR32;
			break;
		default:
			colorFormat = use_gbm ? GBM_FORMAT_XRGB8888 : NvBufferColorFormat_XRGB32;
			break;
	}

	if (use_gbm) {
		buffer->gbm_bo = gbm_bo_create(display->gbm, width, height, colorFormat, GBM_BO_USE_LINEAR);
		if (!buffer->gbm_bo) {
			fprintf(stderr, "error: failed to create gbm buffer with format %X\n", colorFormat);
			return -1;
		}
		// populate the planes info in nvbuf_params
		nvbuf_params.num_planes = gbm_bo_get_plane_count(buffer->gbm_bo);
		nvbuf_params.width[0] = gbm_bo_get_width(buffer->gbm_bo);
		nvbuf_params.height[0] = gbm_bo_get_height(buffer->gbm_bo);
		for (i = 0; i < (int)nvbuf_params.num_planes; i++) {
			nvbuf_params.pitch[i] = gbm_bo_get_stride_for_plane(buffer->gbm_bo, i);
			nvbuf_params.offset[i] = gbm_bo_get_offset(buffer->gbm_bo, i);
		}
	} else {
		CHECK(NvBufferCreate(&buffer->bo.fd, width, height,
    			     NvBufferLayout_Pitch, colorFormat));
		CHECK(NvBufferGetParams(buffer->bo.fd, &nvbuf_params));
	}

	buffer->width = width;
	buffer->height = height;
	buffer->format = format;
	buffer->num_planes = nvbuf_params.num_planes;
	buffer->bo.pitch = nvbuf_params.pitch[0];
	buffer->bo.height = nvbuf_params.height[0];
	buffer->bo.width = nvbuf_params.width[0];

	fill_content(buffer, nvbuf_params, format_info);

	if (opts & OPT_Y_INVERTED)
		flags |= ZWP_LINUX_BUFFER_PARAMS_V1_FLAGS_Y_INVERT;

	params = zwp_linux_dmabuf_v1_create_params(display->dmabuf);

	for (i = 0; i < (int)nvbuf_params.num_planes; i++ ) {
		if (use_gbm) {
			int ret;
			union gbm_bo_handle handle = gbm_bo_get_handle_for_plane(buffer->gbm_bo, i);
			if (handle.s32 == -1) {
				fprintf(stderr, "error: failed to get gbm_bo_handle\n");
				gbm_bo_destroy(buffer->gbm_bo);
				return -1;
			}
			ret = drmPrimeHandleToFD(display->drm_fd, handle.u32, 0,
					 &buffer->bo.fd);
			if (ret < 0 || buffer->bo.fd < 0) {
				fprintf(stderr, "error: failed to get dmabuf_fd\n");
				gbm_bo_destroy(buffer->gbm_bo);
				return -1;
			}
		}
		zwp_linux_buffer_params_v1_add(params,
					       buffer->bo.fd,
					       i,
					       nvbuf_params.offset[i],
					       nvbuf_params.pitch[i],
					       modifier >> 32,
					       modifier & 0xffffffff);
	}

	zwp_linux_buffer_params_v1_add_listener(params, &params_listener,
						buffer);
	if (display->req_dmabuf_immediate) {
		buffer->buffer =
			zwp_linux_buffer_params_v1_create_immed(params,
								nvbuf_params.width[0],
								nvbuf_params.height[0],
								format,
								flags);
		wl_buffer_add_listener(buffer->buffer, &buffer_listener, buffer);
	}
	else {
		zwp_linux_buffer_params_v1_create(params,
						  nvbuf_params.width[0],
						  nvbuf_params.height[0],
						  format,
						  flags);
	}

	return 0;
}

static void
xdg_surface_handle_configure(void *data, struct xdg_surface *surface,
			     uint32_t serial)
{
	struct window *window = data;

	xdg_surface_ack_configure(surface, serial);

	if (window->initialized && window->wait_for_configure)
		redraw(window, NULL, 0);
	window->wait_for_configure = false;
}

static const struct xdg_surface_listener xdg_surface_listener = {
	xdg_surface_handle_configure,
};

static void
xdg_toplevel_handle_configure(void *data, struct xdg_toplevel *toplevel,
			      int32_t width, int32_t height,
			      struct wl_array *states)
{
}

static void
xdg_toplevel_handle_close(void *data, struct xdg_toplevel *xdg_toplevel)
{
	running = 0;
}

static const struct xdg_toplevel_listener xdg_toplevel_listener = {
	xdg_toplevel_handle_configure,
	xdg_toplevel_handle_close,
};

static void
destroy_window(struct display *display, struct window *window)
{
	int i;

	if (window->callback)
		wl_callback_destroy(window->callback);

	if (window->buffers) {
		for (i = 0; i < NUM_BUFFERS; i++) {
			if (!window->buffers[i].buffer)
				continue;

			wl_buffer_destroy(window->buffers[i].buffer);
			destroy_dmabuf_buffer(display->drm_fd, &window->buffers[i]);
		}
		free(window->buffers);
	}

	if (window->xdg_toplevel)
		xdg_toplevel_destroy(window->xdg_toplevel);
	if (window->xdg_surface)
		xdg_surface_destroy(window->xdg_surface);
	wl_surface_destroy(window->surface);
	free(window);
}

static struct window *
create_window(struct display *display, int width, int height, int format,
	      uint32_t opts)
{
	struct window *window;
	int i;
	int ret;

	window = calloc(1, sizeof *window);
	if (!window)
		return NULL;

	window->callback = NULL;
	window->display = display;
	window->width = width;
	window->height = height;
	window->surface = wl_compositor_create_surface(display->compositor);

	if (display->wm_base) {
		window->xdg_surface =
			xdg_wm_base_get_xdg_surface(display->wm_base,
						    window->surface);

		assert(window->xdg_surface);

		xdg_surface_add_listener(window->xdg_surface,
					 &xdg_surface_listener, window);

		window->xdg_toplevel =
			xdg_surface_get_toplevel(window->xdg_surface);

		assert(window->xdg_toplevel);

		xdg_toplevel_add_listener(window->xdg_toplevel,
					  &xdg_toplevel_listener, window);

		xdg_toplevel_set_title(window->xdg_toplevel, "simple-dmabuf");

		window->wait_for_configure = true;
		wl_surface_commit(window->surface);
	} else if (display->fshell) {
		zwp_fullscreen_shell_v1_present_surface(display->fshell,
							window->surface,
							ZWP_FULLSCREEN_SHELL_V1_PRESENT_METHOD_DEFAULT,
							NULL);
	} else {
		assert(0);
	}

	window->buffers = calloc(NUM_BUFFERS, sizeof(*(window->buffers)));
	if (!window->buffers) {
		destroy_window(display, window);
		return NULL;
	}

	for (i = 0; i < NUM_BUFFERS; ++i) {
		ret = create_dmabuf_buffer(display, &window->buffers[i],
					   256, 256, format, opts);

		if (ret < 0) {
			destroy_window(display, window);
			return NULL;
		}
	}

	return window;
}

static struct buffer *
window_next_buffer(struct window *window)
{
	int i;

	for (i = 0; i < NUM_BUFFERS; i++)
		if (!window->buffers[i].busy)
			return &window->buffers[i];

	return NULL;
}

static const struct wl_callback_listener frame_listener;

static void
redraw(void *data, struct wl_callback *callback, uint32_t time)
{
	struct window *window = data;
	struct buffer *buffer;

	buffer = window_next_buffer(window);
	if (!buffer) {
		fprintf(stderr,
			!callback ? "Failed to create the first buffer.\n" :
			"All buffers busy at redraw(). Server bug?\n");
		abort();
	}

	/* XXX: would be nice to draw something that changes here... */

	wl_surface_attach(window->surface, buffer->buffer, 0, 0);
	wl_surface_damage(window->surface, 0, 0, window->width, window->height);

	if (callback)
		wl_callback_destroy(callback);

	window->callback = wl_surface_frame(window->surface);
	wl_callback_add_listener(window->callback, &frame_listener, window);
	wl_surface_commit(window->surface);
	buffer->busy = 1;
}

static const struct wl_callback_listener frame_listener = {
	redraw
};

static void
dmabuf_modifiers(void *data, struct zwp_linux_dmabuf_v1 *zwp_linux_dmabuf,
		 uint32_t format, uint32_t modifier_hi, uint32_t modifier_lo)
{
	struct display *d = data;

	switch (format) {
		case DRM_FORMAT_NV12:
		case DRM_FORMAT_NV16:
		case DRM_FORMAT_NV21:
		case DRM_FORMAT_NV24:
		case DRM_FORMAT_XRGB8888:
		case DRM_FORMAT_ABGR8888:
		case DRM_FORMAT_ARGB2101010:
		case DRM_FORMAT_ABGR2101010:
		case DRM_FORMAT_TEGRA_ABGR2101010_709:
		case DRM_FORMAT_TEGRA_ABGR2101010_2020:
		case DRM_FORMAT_P010:
		case DRM_FORMAT_TEGRA_P010_709:
		case DRM_FORMAT_TEGRA_P010_2020:
		case DRM_FORMAT_YUV420:
		case DRM_FORMAT_YVU420:
		case DRM_FORMAT_YUV444:
			++d->modifiers_count;
			d->modifiers = realloc(d->modifiers,
					       d->modifiers_count * sizeof(*d->modifiers));
			d->modifiers[d->modifiers_count - 1] =
				((uint64_t)modifier_hi << 32) | modifier_lo;
			break;
		default:
			break;
    }
}

static void
dmabuf_format(void *data, struct zwp_linux_dmabuf_v1 *zwp_linux_dmabuf,
	      uint32_t format)
{
	/* XXX: deprecated */
}

static const struct zwp_linux_dmabuf_v1_listener dmabuf_listener = {
	dmabuf_format,
	dmabuf_modifiers
};

static void
xdg_wm_base_ping(void *data, struct xdg_wm_base *shell, uint32_t serial)
{
	xdg_wm_base_pong(shell, serial);
}

static const struct xdg_wm_base_listener wm_base_listener = {
	xdg_wm_base_ping,
};

static void
registry_handle_global(void *data, struct wl_registry *registry,
		       uint32_t id, const char *interface, uint32_t version)
{
	struct display *d = data;

	if (strcmp(interface, "wl_compositor") == 0) {
		d->compositor =
			wl_registry_bind(registry,
					 id, &wl_compositor_interface, 1);
	} else if (strcmp(interface, "xdg_wm_base") == 0) {
		d->wm_base = wl_registry_bind(registry,
					      id, &xdg_wm_base_interface, 1);
		xdg_wm_base_add_listener(d->wm_base, &wm_base_listener, d);
	} else if (strcmp(interface, "zwp_fullscreen_shell_v1") == 0) {
		d->fshell =
			wl_registry_bind(registry,
					 id, &zwp_fullscreen_shell_v1_interface, 1);
	} else if (strcmp(interface, "zwp_linux_dmabuf_v1") == 0) {
		if (version < 3)
			return;
		d->dmabuf = wl_registry_bind(registry,
					     id, &zwp_linux_dmabuf_v1_interface, 3);
		zwp_linux_dmabuf_v1_add_listener(d->dmabuf, &dmabuf_listener, d);
	}
}

static void
registry_handle_global_remove(void *data, struct wl_registry *registry,
			      uint32_t name)
{
}

static const struct wl_registry_listener registry_listener = {
	registry_handle_global,
	registry_handle_global_remove
};

static struct display *
create_display(int opts, int format)
{
	struct display *display;

	display = malloc(sizeof *display);
	if (display == NULL) {
		fprintf(stderr, "out of memory\n");
		return NULL;
	}

	memset(display, 0, sizeof(*display));
	display->drm_fd = open("/dev/dri/card0", O_RDWR);
	if (display->drm_fd < 0) {
		fprintf(stderr, "Couldn't open /dev/dri/card0\n");
		free(display);
		return NULL;
	}

	display->display = wl_display_connect(NULL);
	assert(display->display);

	display->req_dmabuf_immediate = opts & OPT_IMMEDIATE;

	display->registry = wl_display_get_registry(display->display);
	wl_registry_add_listener(display->registry,
				 &registry_listener, display);
	wl_display_roundtrip(display->display);
	if (display->dmabuf == NULL) {
		close(display->drm_fd);
		fprintf(stderr, "No zwp_linux_dmabuf global\n");
		return NULL;
	}

	wl_display_roundtrip(display->display);

	if (opts & OPT_USE_GBM) {
		use_gbm = true;
		display->gbm = gbm_create_device(display->drm_fd);
	}
	// TODO check whether requested format is supported.
	// TODO check whether linear modifier is supported.

	return display;
}

static void
destroy_display(struct display *display)
{
	if (display->dmabuf)
		zwp_linux_dmabuf_v1_destroy(display->dmabuf);

	if (display->wm_base)
		xdg_wm_base_destroy(display->wm_base);

	if (display->fshell)
		zwp_fullscreen_shell_v1_release(display->fshell);

	if (display->compositor)
		wl_compositor_destroy(display->compositor);

	if (use_gbm)
		gbm_device_destroy(display->gbm);

	if (display->drm_fd >= 0)
		close(display->drm_fd);

	wl_registry_destroy(display->registry);
	wl_display_flush(display->display);
	wl_display_disconnect(display->display);
	free(display);
}

static void
signal_int(int signum)
{
	running = 0;
}

static void
print_usage_and_exit(void)
{
	printf("usage flags:\n"
		"\t'--use-gbm'\n\t\tto use gbm buf instead of nvbuf utils\n"
		"\t'--import-immediate=<>'\n\t\t0 to import dmabuf via roundtrip,"
		"\n\t\t1 to enable import without roundtrip\n"
		"\t'--y-inverted=<>'\n\t\t0 to not pass Y_INVERTED flag,"
		"\n\t\t1 to pass Y_INVERTED flag\n"
		"\t'--import-format=<format>'\n\t\tXRGB to import dmabuf as XRGB8888,"
		"\n\t\tNV12 to import dmabuf as NV12\n"
		"\t'--loop=<iterations>'\n\t\tNumber of iterations to execute,"
		"\n\t\tDefault is set to 1\n"
		"\n");
	exit(0);
}

static int
is_true(const char* c)
{
	if (!strcmp(c, "1"))
		return 1;
	if (!strcmp(c, "0"))
		return 0;

	print_usage_and_exit();
	return 0;
}

static int
parse_import_format(const char* c)
{
	if (!strcmp(c, "XRGB"))
		return DRM_FORMAT_XRGB8888;
	if (!strcmp(c, "ABGR"))
		return DRM_FORMAT_ABGR8888;
	if (!strcmp(c, "ARGB2101010"))
		return DRM_FORMAT_ARGB2101010;
	if (!strcmp(c, "TEGRA_ARGB2101010_709"))
		return DRM_FORMAT_TEGRA_ARGB2101010_709;
	if (!strcmp(c, "TEGRA_ARGB2101010_2020"))
		return DRM_FORMAT_TEGRA_ARGB2101010_2020;
	if (!strcmp(c, "ABGR2101010"))
		return DRM_FORMAT_ABGR2101010;
	if (!strcmp(c, "TEGRA_ABGR2101010_709"))
		return DRM_FORMAT_TEGRA_ABGR2101010_709;
	if (!strcmp(c, "TEGRA_ABGR2101010_2020"))
		return DRM_FORMAT_TEGRA_ABGR2101010_2020;
	if (!strcmp(c, "NV12"))
		return DRM_FORMAT_NV12;
	if (!strcmp(c, "NV21"))
		return DRM_FORMAT_NV21;
	if (!strcmp(c, "NV16"))
		return DRM_FORMAT_NV16;
	if (!strcmp(c, "NV24"))
		return DRM_FORMAT_NV24;
	if (!strcmp(c, "P010"))
		return DRM_FORMAT_P010;
	if (!strcmp(c, "TEGRA_P010_709"))
		return DRM_FORMAT_TEGRA_P010_709;
	if (!strcmp(c, "TEGRA_P010_2020"))
		return DRM_FORMAT_TEGRA_P010_2020;
	if (!strcmp(c, "YUV420"))
		return DRM_FORMAT_YUV420;
	if (!strcmp(c, "YVU420"))
		return DRM_FORMAT_YVU420;
	if (!strcmp(c, "YUV444"))
		return DRM_FORMAT_YUV444;

	print_usage_and_exit();
	return 0;
}

int
main(int argc, char **argv)
{
	struct sigaction sigint;
	struct display *display;
	struct window *window;
	int i, opts = 0, loops = 1;
	int import_format = DRM_FORMAT_XRGB8888;
	int c, option_index, ret = 0;

	static struct option long_options[] = {
		{"use-gbm",          no_argument      , 0,  'g' },
		{"import-format",    required_argument, 0,  'f' },
		{"import-immediate", required_argument, 0,  'i' },
		{"y-inverted",       required_argument, 0,  'y' },
		{"help",             no_argument      , 0,  'h' },
		{"loop",             required_argument, 0,  'l' },
		{0, 0, 0, 0}
	};

	while ((c = getopt_long(argc, argv, "hf:i:y:l:g:",
				  long_options, &option_index)) != -1) {
		switch (c) {
		case 'f':
			import_format = parse_import_format(optarg);
			break;
		case 'i':
			if (is_true(optarg))
				opts |= OPT_IMMEDIATE;
			break;
		case 'y':
			if (is_true(optarg))
				opts |= OPT_Y_INVERTED;
			break;
		case 'l':
			loops = atoi(optarg);
			break;
		case 'g':
			opts |= OPT_USE_GBM;
			break;
		default:
			print_usage_and_exit();
		}
	}

	display = create_display(opts, import_format);
	if (!display)
		return 1;

	window = create_window(display, 256, 256, import_format, opts);
	if (!window) {
		destroy_display(display);
		return 1;
	}

	sigint.sa_handler = signal_int;
	sigemptyset(&sigint.sa_mask);
	sigint.sa_flags = SA_RESETHAND;
	sigaction(SIGINT, &sigint, NULL);

	/* Here we retrieve the linux-dmabuf objects if executed without immed,
	 * or error */
	wl_display_roundtrip(display->display);

	if (!running)
		return 1;

	window->initialized = true;

	if (!window->wait_for_configure)
		redraw(window, NULL, 0);

	for (i = 0; i < loops; i++) {
		ret = wl_display_dispatch(display->display);
		if(ret < 0)
			break;
	}

	if (ret < 0)
		fprintf(stderr,"\nTEST FAILED\n");
	else fprintf(stdout,"\nTEST PASSED\n");

	fprintf(stdout, "simple-dmabuf exiting\n");

	destroy_window(display, window);
	destroy_display(display);

	return 0;
}
