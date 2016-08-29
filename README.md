# Fun with Distance Fields
I'm experimenting with doing various things with distance fields. The first experiment was implementing this as an image effect, i.e. a full-screen shader. This one only has the basic features implemented (no AO or shadows), although simle diffuse lighting is supported.

The sphere tracing algorithm is used to ray-march the distance fields. I've made the optimization of increasing the allowed distance from the surface `eps` as the iterations go up. This allows for the maximum number of iterations to be 25 rather than 40 for the current scene. The value starts at 0.01 and increases linearly to 0.1.

The next experiment was getting the shader to work together with regular Unity transforms, so that placing the ray-marched objects in the world is easy. Currently it has been implemented as an unlit shader and can be used as material on any object. This means that the result of the ray-marching is sort-of "contained" within whatever object the shader is applied to. I figure that this is nice for some effects, like if one were to make volumetric fire.

In order to ray-march we need a ray. The first example constructed this ray based on UV screen coordinates. For the second experiment, we can actually do something smarter which doesn't require any changes to the distance field functions, while still respecting the object transform.

The ray is constructed by first of all transforming the camera position from world to model space. The ray direction is then the direction from the camera position (in model space) to the current vertex position (also in model space). The ray origin is then simply the vertex position, since nothing can appear outside of the object.

By having the ray in model-space, we can easily use it with the distance field functions, as they also operate in model space. The ray direction and origin is calculated in the vertex shader and then interpolated for the fragment shader.

Currently the second experiment has support for Phong-lighting along with ambient occlusion and soft shadows. The lighting uses the first light available. The ambient light gets its color from `unity_AmbientSky`.

## To do
- Rather than using arbitrary 3D objects, use a quad that automatically aligns with the screen. Fewer vertices to calculate rays for, as well as fewer interpolation issues.
- Integrate with the G-Buffer in order to take advantage of Unity's PBR shaders.
- Something actually cool (rather than just solid objects), like a light saber or something.
- Volumetric rendering, e.g. thick fog or maybe even a light saber.
- Optimize ray-marching, e.g. using techniques from *Enhanced Sphere Tracing (Keinert et al.)*

## Renders

AO and soft shadows in action. ([video](https://dl.dropboxusercontent.com/u/152195/ShareX/2016/08/2016-08-22_17-16-30.mp4))

Infinite twisting pillars. ([video](https://dl.dropboxusercontent.com/u/152195/ShareX/2016/08/2016-08-29_10-46-27.mp4))

Object transform being respected. ([video](https://dl.dropboxusercontent.com/u/152195/ShareX/2016/08/2016-08-29_10-58-43.mp4))

Ambient occlusion:  
![Ambient occlusion](http://i.imgur.com/dpsJZ82.png)

Early rendering:  
![Early version](http://i.imgur.com/OOXeT2q.png)
